local math = require("math")
local {hudIsInteractive} = require("state/interactive_state.nut")
local cursors = require("ui/style/cursors.nut")
local {horPadding, verPadding} = require("globals/safeArea.nut")
local {debug_borders,
  rightPanelTop, rightPanelMiddle, rightPanelBottom,
  centerPanelBottom, centerPanelMiddle, centerPanelTop,
  leftPanelBottom, leftPanelMiddle, leftPanelTop,
  centerPanelBottomStyle, centerPanelTopStyle, centerPanelMiddleStyle,
  rightPanelBottomStyle, rightPanelTopStyle, rightPanelMiddleStyle,
  leftPanelBottomStyle, leftPanelTopStyle, leftPanelMiddleStyle
} = require("state/hud_layout_state.nut")

local debug_borders_robj = @() (debug_borders.value ) ? ROBJ_FRAME: null

local function debug_colors() {
  return Color(math.rand()*155/math.RAND_MAX+100, math.rand()*155/math.RAND_MAX+100, math.rand()*155/math.RAND_MAX+100)
}

local function mpanel(watched, params={}) {
  return @() {
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_TOP
    halign = ALIGN_LEFT
    rendObj = debug_borders_robj()
    color = debug_colors()
    gap = sh(1)
  }.__update(params).__update({ watch=watched children=watched.value})
}


local function panel(params={}) {
  local size = params?.size ?? flex()
  local children = params?.children ?? []
  local watch = params?.watch ?? []
  return {
    size = size
    rendObj = debug_borders_robj()
    color = debug_colors()
    flow = FLOW_VERTICAL
    padding = sh(1)
    children = children
    watch = watch
  }
}

local function leftPanel(params={}) {
  return panel (params.__merge({
    watched = [leftPanelTop,leftPanelMiddle,leftPanelBottom]
    size = flex(1)
    children = [
      mpanel(leftPanelTop,{ size =[flex(),flex(1)] }.__update(leftPanelTopStyle.value))
      mpanel(leftPanelMiddle, { valign = ALIGN_BOTTOM size =[flex(),flex(3)] minHeight = SIZE_TO_CONTENT}.__update(leftPanelMiddleStyle.value))
      mpanel(leftPanelBottom, {  valign = ALIGN_BOTTOM maxHeight = flex(1) size = [flex(),SIZE_TO_CONTENT]}.__update(leftPanelBottomStyle.value))
    ]
  }))
}
local function centerPanel(params={}) {
  return panel (params.__merge({
    watched = [
      centerPanelTop, centerPanelMiddle, centerPanelBottom,
      centerPanelTopStyle, centerPanelMiddleStyle, centerPanelBottomStyle
    ]
    size = flex(2)
    children = [
      mpanel(centerPanelTop, {halign = ALIGN_CENTER, size = [flex(),flex(3)]}.__update(centerPanelTopStyle.value))
      mpanel(centerPanelMiddle, {halign = ALIGN_CENTER, valign = ALIGN_BOTTOM, size = [flex(),flex(2)]}.__update(centerPanelMiddleStyle.value))
      mpanel(centerPanelBottom, {halign = ALIGN_CENTER valign = ALIGN_BOTTOM, size = [flex(), flex(1)]}.__update(centerPanelBottomStyle.value))
    ]
  }))
}

local function rightPanel(params={}) {
  return panel(params.__merge({
    watched = [rightPanelTop, rightPanelMiddle, rightPanelBottom]
    size = flex(1)
    children = [
      mpanel(rightPanelTop, { size =[flex(),flex(1)] halign=ALIGN_RIGHT}.__update(rightPanelTopStyle.value))
      mpanel(rightPanelMiddle, { size =[flex(),flex(2)] halign=ALIGN_RIGHT valign=ALIGN_CENTER}.__update(rightPanelMiddleStyle.value))
      mpanel(rightPanelBottom, { size =[flex(),flex(1)] halign=ALIGN_RIGHT valign=ALIGN_BOTTOM}.__update(rightPanelBottomStyle.value))
    ]
  }))
}

local function footer(size) {
  return {
    size = [flex(), size]
    rendObj = debug_borders_robj()
    color = debug_colors()
  }
}

local function header(size) {
  return {
    size = [flex(), size]
    rendObj = debug_borders_robj()
    color = debug_colors()
    flow = FLOW_HORIZONTAL
    padding = [0,sh(2),0,sh(2)]
  }
}

local function HudLayout() {
  local children = []
  children = [
    header(::max(verPadding.value, sh(3)))
    {
      flow = FLOW_HORIZONTAL
      size = flex()
      children = [
        {size = [::max(sh(4), horPadding.value),flex()]} //leftPadding
        leftPanel({size=[sh(40),flex()]})
        centerPanel()
        rightPanel({szie=[sh(40),flex()]})
        {size = [::max(sh(4), horPadding.value),flex()]} //rightPadding
      ]
    }
    footer(::max(verPadding.value, sh(2.5)))
  ]
  local desc = {
    size = flex()
    flow = FLOW_VERTICAL
    watch = [debug_borders, hudIsInteractive, horPadding, verPadding]
    children = children
  }

  if (hudIsInteractive.value)
    desc.cursor <- cursors.normal

  return desc
}

return HudLayout
 