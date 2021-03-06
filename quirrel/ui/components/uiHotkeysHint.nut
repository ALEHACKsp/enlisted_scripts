local formatInputBinding = require("ui/control/formatInputBinding.nut")
local parseDargHotkeys =  require("ui/components/parseDargHotkeys.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local style = require("ui/hud/style.nut")

local function makeHintRow(hotkeys, params={}) {
  local textFunc = params?.textFunc ??@(text) {
    rendObj = ROBJ_DTEXT
    text = text
    color = style.HUD_TIPS_HOTKEY_FG
    font = params?.font ?? Fonts.small_text
  }
  local noWatchGamepad = params?.column != null
  return function(){
    local isGamepadV = noWatchGamepad ? params.column == 1 : isGamepad.value
    local rowTexts = parseDargHotkeys(hotkeys)?[isGamepadV ? "gamepad" : "kbd"] ?? []
    if (rowTexts.len() == 0)
      return null
    return {
      watch = noWatchGamepad ? null : isGamepad
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = ::hdpx(10)
      vplace = ALIGN_CENTER
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = formatInputBinding.buildElems(rowTexts, { textFunc = textFunc})
    }.__merge(params)
  }
}
local function mkHotkey(hotkey, action, params={}){
  return {
    children = makeHintRow(hotkey, params)
    size = SIZE_TO_CONTENT
    hotkeys = [[hotkey, {action=action, description={skip=true}}]]
  }.__merge(params)
}

return {
  mkHintRow = makeHintRow
  mkHotkey
} 