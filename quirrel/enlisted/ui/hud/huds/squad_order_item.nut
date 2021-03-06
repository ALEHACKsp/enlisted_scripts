local {controlHudHint} = require("ui/hud/components/controlHudHint.nut")
local controlText = require("ui/hud/components/controlText.nut")
local {controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")

local function orderItem(params={hotkey=null, text=null, handler=null,showIfNoHotkey=true}) {
  local showIfNoHotkey = params?.showIfNoHotkey ?? true
  local hotkey = params?.hotkey ?? ""
  local text = params?.text
  local handler = params?.handler ?? @() null
  local cText = controlText({id=hotkey})

  local hint = controlHudHint({id=hotkey, hplace = ALIGN_RIGHT text_params = {font = Fonts.small_text} frame=false} )
  return function(){
    local children
    if (showIfNoHotkey || (cText && cText != "")) {
      children = [
        {size = [fontH(200),10]  font = Fonts.small_text  vplace = ALIGN_CENTER  valign = ALIGN_CENTER halign = ALIGN_RIGHT children = hint}
        {rendObj = ROBJ_DTEXT text=text color = Color(160,160,120) font=Fonts.small_text}
      ]
    }

    return {
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = sh(0.5)
      watch = [controlledHeroEid]
      children = children
      eventHandlers = {
        [hotkey] = function(event) {
          handler(controlledHeroEid.value)
          return EVENT_BREAK
        }
      }
    }
  }
}
return orderItem 