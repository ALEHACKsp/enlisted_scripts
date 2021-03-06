local style = require("ui/hud/style.nut")
local { menuRowColor } = require("ui/style/menuColors.nut")
local cursors = require("ui/style/cursors.nut")

local JB = require("ui/control/gui_buttons.nut")


local optionLabel = require("ui/components/optionLabel.nut")
local textButton = require("enlist/components/textButton.nut")
local scrollbar = require("ui/components/scrollbar.nut")
local active_controls = require("ui/control/active_controls.nut")
local settingsHeaderTabs = require("settingsHeaderTabs.nut")


local windowButtons = @(params) function() {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = style.CONTROL_BG_COLOR

    children = params?.buttons || [
      textButton(::loc("mainmenu/btnApply"), params.applyHandler(params.options))
      textButton(::loc("mainmenu/btnCancel"), params.cancelHandler)
    ]

    eventHandlers = {
      [JB.B] = @(event) params.cancelHandler(),
    }
  }
}

local function optionRowContainer(children, isOdd) {
  local stateFlags = ::Watched(0)
  return @() {
    watch = stateFlags
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    skipDirPadNav = true
    children = children
    rendObj = ROBJ_SOLID
    color = menuRowColor(stateFlags.value, isOdd)
    gap = sh(2)
  }
}

local function makeOptionRow(opt, isOdd) {
  local group = ::ElemGroup()
  local xmbNode = ::XmbNode()
  if ("rowCtor" in opt)
    return opt.rowCtor(opt, group) ?? {}

  local widget = opt.widgetCtor(opt, group, xmbNode)
  if (!widget)
    return {}

  local baseHeight = sh(5.5)
  local height = baseHeight
  local label = opt?.names ? (function() {
    height *= opt.names.len()
    return {
      size = [flex(), height]
      flow = FLOW_VERTICAL
      valign = ALIGN_CENTER
      children = opt.names.map(@(name) {
        size = [pw(100), baseHeight]
        valign = ALIGN_CENTER
        children = optionLabel(opt.__merge({ name = name }), group)
      })
     }
  })() : optionLabel(opt, group)

  local row = {
    padding = [hdpx(8), sh(8)]
    size = [flex(), height]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = sh(2)
    children = [
      label
      widget
    ]
  }

  return optionRowContainer(row, isOdd)
}


local function optionsPage(params) {
  local xmbNode = ::XmbContainer({wrap=true})

  return function() {
    local optionControls = []

    local isOdd = true
    foreach (opt in params.options) {
      if (opt.tab == params.currentTab.value) {
        optionControls.append(makeOptionRow(opt, isOdd))
        isOdd = !isOdd
      }
    }

    return {
      size = flex()
      watch = params.currentTab
      behavior = Behaviors.Button
      onClick = params?.onPageClick

      children = scrollbar.makeVertScroll({
        flow = FLOW_VERTICAL
        xmbNode = xmbNode
        key = params.currentTab.value
        size = [flex(), SIZE_TO_CONTENT]
        padding = [sh(1), 0]
        clipChildren = true
        animations = [
          { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
          { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
        ]

        children = optionControls
      })
    }
  }
}


local function settingsMenu(params) {

  return @(){
    size = [sw(100), sh(100)]
    cursor = cursors.normal
    watch = [active_controls.isGamepad]
    key = params?.key
    children = {
      //parallaxK = active_controls.isGamepad.value ? -0.1 : 0
      //behavior = [Behaviors.Parallax]
      transform = {}
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size = params?.size ?? [sh(90), sh(80)]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = Color(120,120,120,255)
      flow = FLOW_VERTICAL
      //stopHotkeys = true
      stopMouse = true
      hooks = HOOK_ATTACH
      actionSet = "StopInput"

      children = [
        settingsHeaderTabs(params)
        optionsPage(params)
        windowButtons(params)
      ]
    }
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
    ]
  }
}


return settingsMenu
 