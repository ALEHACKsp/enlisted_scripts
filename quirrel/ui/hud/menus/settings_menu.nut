local ipc = require("ipc")
local {apply_video_settings} = require("videomode")
local {apply_audio_settings=@() null} = require_optional("sound")
local {defCmp} = require("options/options_lib.nut")
local log = require("std/log.nut")().with_prefix("[SettingsMenu] ")
local textButton = require("enlist/components/textButton.nut")
local JB = require("ui/control/gui_buttons.nut")
local settingsMenuCtor = require("ui/components/settingsMenu.nut")
local msgbox = require("ui/components/msgbox.nut")
local {menuOptions, menuTabsOrder} = require("settings_menu_state.nut")
local { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")

local showSettingsMenu = persist("showSettingsMenu", @() Watched(false))

local onlineSettingUpdated = require_optional("onlineStorage")
  ? require("enlist/options/onlineSettings.nut").onlineSettingUpdated : null

local closeMenu = @() showSettingsMenu(false)

//====internal state
local foundTabsByOptions = Watched([])
local resultOptions = Watched([])

local function setResultOptions(...){
  local optionsValue = menuOptions.value
  local tabsInOptions = {}
  local isAvailableTriggers = optionsValue.filter(@(opt) opt?.isAvailableWatched!=null).map(@(opt) opt.isAvailableWatched)
  optionsValue = optionsValue.filter(@(opt) (opt?.isAvailable==null && opt?.isAvailableWatched==null) || opt?.isAvailable() || opt?.isAvailableWatched.value)
  foreach (opt in optionsValue) {
    if (opt?.tab != null ) {
      if (tabsInOptions?[opt.tab] == null)
        tabsInOptions[opt.tab] <- true
    }
    else{
      tabsInOptions["__unknown__"] <- true
    }
    if (opt?.originalVal == null)
      opt.originalVal <- (type(opt?.blkPath)==type("") ? get_setting_by_blk_path(opt.blkPath)
        : opt?.var ? opt.var.value
        : null
      ) ?? opt?.defVal

    if (!("var" in opt))
      opt.var <- Watched(opt.originalVal)
    if (!("isEqual" in opt))
      opt.isEqual <- defCmp
  }
  resultOptions(optionsValue)
  foundTabsByOptions(tabsInOptions.keys())
  foreach(i in isAvailableTriggers)
    i.subscribe(setResultOptions)

}
menuOptions.subscribe(setResultOptions)
setResultOptions()

local resultTabs = Computed(function(){
  local tabsOrder = menuTabsOrder.value
  local foundTabsByOptionsValue = foundTabsByOptions.value
  local selectedTabs = []
  local ret = []
  foreach (tab in tabsOrder) {
    if (foundTabsByOptionsValue.indexof(tab?.id)!=null && selectedTabs.indexof(tab?.id)==null) {
      ret.append(tab)
      selectedTabs.append(tab.id)
    }
  }
  foreach (id in foundTabsByOptionsValue)
    if (tabsOrder.findindex(@(tab) tab?.id == id) == null)
      ret.append({id=id, text=::loc(id)})
  return ret
})

local curTab = persist("currentTab", @() Watched(null))
local currentTab = persist("currentTab", @() Watched(menuTabsOrder.value?[0].id))


local function applyGameSettingsChanges(optionsValue) { //FIX ME: should to divide ui and state logic in this file
  local needRestart = false
  local changedFields = []
  foreach(opt in optionsValue) {
    if ("blkPath" in opt) {
      local hasChanges = false
      local val = opt.var.value
      if ("convertForBlk" in opt)
        val = opt.convertForBlk(val)
      local blksettings = [{blkPath=opt.blkPath, val=val, defVal = opt?.defVal}]
      if ("getMoreBlkSettings" in opt)
        blksettings.extend(opt.getMoreBlkSettings(opt.var.value))
      foreach (setting in blksettings) {
        if (!opt.isEqual(get_setting_by_blk_path(setting.blkPath) ?? setting?.defVal, setting.val)) {
          set_setting_by_blk_path(setting.blkPath, setting.val)
          changedFields.append(setting.blkPath)
          hasChanges = true
        }
      }
      if (hasChanges && opt?.restart)
        needRestart = true
    }
  }
  log("apply changes", changedFields)
  save_settings()
  apply_video_settings(changedFields)
  apply_audio_settings(changedFields)
  return needRestart
}

local saveAndApply = @(onMenuClose, options) function() {
  local needRestart = applyGameSettingsChanges(options)
  onMenuClose()
  ipc.send({ msg = "onlineSettings.sendToServer" })

  if (needRestart) {
    msgbox.show({text=::loc("settings/restart_needed")})
  }
}

if (onlineSettingUpdated)
  onlineSettingUpdated.subscribe(
    @(val) val ? ::gui_scene.setTimeout(0.01, @() applyGameSettingsChanges(resultOptions.value)) : null)

resultOptions.subscribe(@(v) applyGameSettingsChanges(v))

local function mkSettingsMenuUi(menu_params) {
  local function close(){
    menu_params?.onClose()
    closeMenu()
  }
  return function(){
    local optionsValue = resultOptions.value
    local tabs = resultTabs.value
    return {
      size = flex()
      key = "settings_menu_root"
      onDetach = @() curTab(tabs?[0].id ?? "")
      function onAttach(){
        if ((curTab.value ?? "") == "")
          curTab(tabs?[0].id ?? "")
      }
      watch = [resultTabs, resultOptions, currentTab]
      children = settingsMenuCtor({
        key = "settings_menu"
        size = [sw(70), sh(80)]
        options = optionsValue
        sourceTabs = tabs
        currentTab = currentTab
        onClose = close
        buttons = [
          { size=flex(), flow = FLOW_HORIZONTAL, children = menu_params?.leftButtons }
          textButton(::loc("Ok"), saveAndApply(close, optionsValue), {
            hotkeys = [
              ["^{0} | J:Start | Esc".subst(JB.B), {action=saveAndApply(closeMenu, optionsValue), description={skip=true}}],
            ],
            skipDirPadNav = true
          })
        ]
        cancelHandler = @() null
      })
    }
  }
}

return {
  mkSettingsMenuUi = mkSettingsMenuUi
  showSettingsMenu = showSettingsMenu
}
 