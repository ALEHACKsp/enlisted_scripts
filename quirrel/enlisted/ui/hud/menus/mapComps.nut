local uiHotkeysHint = require("ui/components/uiHotkeysHint.nut").mkHintRow
local formatInputBinding = require("ui/control/formatInputBinding.nut")
local JB = require("ui/control/gui_buttons.nut")

local hintTextFunc = @(text, color = Color(128,128,128,128)) {
  rendObj = ROBJ_DTEXT
  text
  color
  font = Fonts.medium_text
}

local function mkTips(keys, locId){
  return {
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(10)
    children = formatInputBinding.buildElems(keys, { textFunc = hintTextFunc })
      .append(hintTextFunc(::loc(locId)))
  }
}

local function makeHintRow(hotkeys, text) {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(10)
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [uiHotkeysHint(hotkeys,{textFunc=hintTextFunc})].append(hintTextFunc(text))
  }
}

local mouseNavTips = mkTips(["MMB"], "map/bigMapPan")
local placePointsTipGamepad = {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    makeHintRow(JB.A, ::loc("map/place_marks/gamepad"))
  ]
}
local navGamepadHints = {
  flow = FLOW_HORIZONTAL
  gap = sh(5)
  children = [
    mkTips(["J:LT", "J:RT"], "map/zoom")
    mkTips(["J:R.Thumb.hv"], "map/bigMapPan")
  ]
}

local placePointsTipMouse = mkTips(["RMB"], "map/place_marks/gamepad")

return {hintTextFunc, mouseNavTips, placePointsTipGamepad, navGamepadHints, mkTips, makeHintRow, placePointsTipMouse}
 