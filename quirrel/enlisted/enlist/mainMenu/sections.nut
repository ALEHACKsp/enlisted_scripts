local { lerp } = require("std/math.nut")
local { safeAreaAmount, safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { TextActive, Active, TextHighlight, TextDefault } = require("ui/style/colors.nut")
local { horGap } = require("enlist/components/commonComps.nut")
local { sectionsSorted, curSection, setCurSection } = require("sectionsState.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local JB = require("ui/control/gui_buttons.nut")
local { mkHotkey } = require("ui/components/uiHotkeysHint.nut")

if (sectionsSorted.value?.len() && !(sectionsSorted.value ?? []).findvalue(@(s) s?.id == curSection.value))
  setCurSection(sectionsSorted.value?[0].id)

local getActiveSections = @() (sectionsSorted.value ?? []).filter(@(s) !s?.watch || s?.watch.value)

local function defCtor(section, stateFlags, group, isCurrent){
  return function(){
    local color
    local fontFx = FFT_NONE
    if (isCurrent.value) {
      color = Active
      fontFx = FFT_GLOW
    } else {
      local sf = stateFlags.value
      color = (sf & S_ACTIVE) ? TextActive
              : (sf & S_HOVER) ? TextHighlight
              : TextDefault
    }
    local children = [{
      rendObj = ROBJ_DTEXT
      font = Fonts.big_text
      text = ::loc(section.locId)
      color = color
      fontFx = fontFx
      fontFxColor = TextDefault
      fontFxFactor = 48
      group = group
    }]
    if (section?.unseenWatch)
      children.append(@(){
        watch = section?.unseenWatch
        hplace = ALIGN_RIGHT
        pos = [hdpx(15),-hdpx(10)]
        children = section?.unseenWatch.value ? unseenSignal(0.8) : null
      })
    return {
      size = SIZE_TO_CONTENT
      children = children
      group = group
    }
  }
}

local function sectionLink(section) {
  local stateFlags = Watched(0)
  local isCurrent = ::Computed(@() section.id==curSection.value)
  local group = ::ElemGroup()
  local ctor = section?.ctor ?? defCtor
  return function() {
    local children = ctor(section, stateFlags, group, isCurrent)

    return {
      watch = [stateFlags, isCurrent]
      key = section.id
      padding = [sh(1), 0]
      behavior = Behaviors.Button
      skipDirPadNav = true
      sound = {
        click  = "ui/enlist/button_click"
        hover  = "ui/enlist/button_highlight"
        active = "ui/enlist/button_action"
      }
      onClick = @() setCurSection(section.id)
      onElemState = @(sf) stateFlags(sf)
      group = group
      valign = ALIGN_CENTER
      children = children
      size = SIZE_TO_CONTENT
    }
  }
}

local sectionsHotkeys = @() {
  watch = [curSection, sectionsSorted]
  children = curSection.value != getActiveSections()?[0].id
    ? {
        key ="back"
        hotkeys = [["^{0} | Esc".subst(JB.B), {action = @() setCurSection(getActiveSections()?[0].id), description = ::loc("Back")}]]
      }
    : null
}

local function changeTab(delta, cycle=false) {
  local filtered = getActiveSections()
  local next_idx = (filtered.findindex(@(val) val.id == curSection.value) ?? -1) + delta
  local total = filtered.len()
  setCurSection(filtered[cycle ? ((next_idx + total) % total) : ::clamp(next_idx, 0, total - 1)].id)
}

local function sectionsUi() {
  local changeTabWrap = @(delta) changeTab(delta, true)
  local maintabs = @() {
    gap = horGap
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = getActiveSections().map(@(s) sectionLink(s))
    watch = sectionsSorted.value?.map(@(s) s?.watch).filter(@(w) w != null).append(sectionsSorted)
  }
  local tb = @(key, action) @() {
    children = mkHotkey(key, action)
    isHidden = !isGamepad.value
    watch = isGamepad
    size = SIZE_TO_CONTENT
  }
  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    rendObj = ROBJ_WORLD_BLUR_PANEL
    gap = sh(1)
    children = [
      {hotkeys=[["^Tab", @() changeTabWrap(1)], ["^L.Shift Tab | R.Shift Tab", @() changeTabWrap(-1)]]}
      tb("^J:LB", @() changeTab(-1))
      maintabs
      tb("^J:RB", @() changeTab(1))
    ]
  }
}

local lerp_navbar_margin = @(v) lerp(0.9, 1.0, 0.3, 1, v)

local defNavHeaderHeight = ::calc_comp_size({size=SIZE_TO_CONTENT children={font=Fonts.big_text margin = [sh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_DTEXT}})[1]
local navHeaderHeight = Watched(defNavHeaderHeight)
local menuHeaderRightUiList = ::Watched([])
local menuRightUiComp = function(){
  return {
    watch = [menuHeaderRightUiList, navHeaderHeight]
    children = menuHeaderRightUiList.value
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    size = [SIZE_TO_CONTENT, navHeaderHeight.value]
    rendObj = ROBJ_WORLD_BLUR_PANEL
  }
}
local function navHeader() {
  local padding = clone safeAreaBorders.value
  padding = [0, max(padding[1], sh(1)), 0, max(padding[3], sh(0.5))]

  return {
    size = [flex(), navHeaderHeight.value]
    margin = [0, 0, sh(2) * lerp_navbar_margin(safeAreaAmount.value)]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    padding
    watch = [safeAreaBorders, menuHeaderRightUiList, navHeaderHeight]
    children = [
      sectionsUi
      {size=[flex(),0]}
      menuRightUiComp
    ].append(sectionsHotkeys)
  }
}

return {
  navHeader
  navHeaderHeight
  menuHeaderRightUiList
} 