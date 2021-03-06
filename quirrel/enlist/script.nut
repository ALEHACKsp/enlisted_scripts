#default:no-func-decl-sugar
#default:no-class-decl-sugar

require("daRg/library.nut")
require("ui/enlisted-lib.nut")

::VM_NAME <- "enlist"

::ecs.clear_vm_entity_systems()
require("options/onlineSaveDataHub.nut")
local {get_game_name} = require("app")
require_optional($"{get_game_name()}/enlist/onScriptLoad.nut")
require("ui/ui_config.nut")
require("voiceChat/voiceStateHandlers.nut")
require("enlist/state/roomState.nut")
require("debriefing/debriefing_dbg.nut")
require("login/initLogin.nut")

local friendlyErrorsBtn = require("friendly_logerr.ui.nut")
local hotkeys = require("ui/hotkeysPanel.nut")
local platform = require("globals/platform.nut")
local cursors = require("ui/style/cursors.nut")
local msgbox = require("components/msgbox.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local {isLoggedIn} = require("enlist/login/login_state.nut")
local mainScreen = require("mainScreen.nut")
local inspector = require("daRg/components/inspector.nut")
local globInput = require("ui/glob_input.nut")
local {DBGLEVEL} = require("dagor.system")
local {popupBlock} = require("enlist/popup/popupBlock.nut")
local registerScriptProfiler = require("utils/regScriptProfiler.nut")
local {underUiLayer, aboveUiLayer} = require("enlist/uiLayers.nut")
local {safeAreaAmount,safeAreaVerPadding, safeAreaHorPadding} = require("globals/safeArea.nut")
local fadeToBlack = require("fadeToBlack.nut").ui
local loginScreen = require("login/currentLoginUi.nut")
local version_info = require("components/versionInfo.nut")
local {noServerStatus, saveDataStatus} = require("enlist/mainMenu/info_icons.nut")
local speakingList = require("ui/speaking_list.nut")

local {mkSettingsMenuUi, showSettingsMenu} = require("ui/hud/menus/settings_menu.nut")
local emailLinkButton = require("mkLinkButton.nut")
local settingsMenuUi = mkSettingsMenuUi({
  onClose = @() showSettingsMenu(false)
  leftButtons = [ emailLinkButton ]
})
local {controlsMenuUi, showControlsMenu} = require("ui/hud/menus/controls_setup.nut")

local onPlatfomLoadModulePath = platform.is_xdk ? "enlist/xbox/onLoadXboxXDK.nut"
  : platform.is_gdk ? "enlist/xbox_gdk/onLoadXboxGDK.nut"
  : platform.is_sony ? "enlist/ps4/onLoadPs4.nut"
  : platform.is_nswitch ? "enlist/nswitch/onLoadNswitch.nut"
  : null
if (onPlatfomLoadModulePath != null)
  require(onPlatfomLoadModulePath)

require("netUtils.nut")
require("autoexec.nut")
require("charClient.nut")
require("enlist/notifications.nut")
require("globals/chat/chatState.nut").subscribeHandlers()

registerScriptProfiler("enlist")

inspector.cursors.normal = cursors.normal
inspector.cursors.pick = cursors.normal

local fpsBar = DBGLEVEL > 0 ? {
  rendObj = ROBJ_DTEXT
  behavior = Behaviors.FpsBar
  font = Fonts.tiny_text
  size = [sh(15), SIZE_TO_CONTENT]
} : null

local underUi = @(){
  size = flex()
  watch = underUiLayer.state
  children = underUiLayer.getComponents()
}

local aboveUi = @(){
  size = flex()
  watch = aboveUiLayer.state
  children = aboveUiLayer.getComponents()
}

local msgboxesUI = @(){
  watch = msgbox.widgets
  children = msgbox.widgets.value
}

local logerrsUi = @(){
  watch = safeAreaAmount
  halign = ALIGN_RIGHT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER size = [sw(100)*safeAreaAmount.value, sh(100)*safeAreaAmount.value]
  children = friendlyErrorsBtn
}

local infoIcons = @(){
  margin = [max(safeAreaVerPadding.value/2.0,sh(0.4)), max(safeAreaHorPadding.value/1.2,sh(0.4))]
  watch = [safeAreaHorPadding, safeAreaVerPadding]
  children = [noServerStatus, saveDataStatus]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
}

local function curScreen(){
  local children
  if (showSettingsMenu.value)
    children = settingsMenuUi
  else if (showControlsMenu.value)
    children = controlsMenuUi
  else if (isLoggedIn.value == false)
    children = loginScreen.value.comp
  else
    children = mainScreen
  return {
    size = flex()
    watch = [isLoggedIn, loginScreen, showControlsMenu, showSettingsMenu]
    children = children
  }
}

return function Root() {
  return {
    cursor = cursors.normal
    watch = [ ::gui_scene.isActive ]
    children = !::gui_scene.isActive.value ? null : [
      globInput, fadeToBlack, underUi,
      curScreen, version_info, aboveUi, modalWindows.component,
      msgboxesUI, popupBlock, speakingList, logerrsUi, infoIcons, inspector.root, fpsBar, hotkeys
    ]
  }
}

 