local {warningsList} = require("ui/hud/state/warnings.nut")

local warnText = ::kwarg(@(locId, color = null) {
  size = [sh(100), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior=Behaviors.TextArea
  halign = ALIGN_CENTER
  font = Fonts.big_text
  color = color ?? Color(255,180,180,200)
  fontFxColor = Color(0, 0, 0, 50)
  fontFxFactor = 64
  fontFx = FFT_GLOW
  text = ::loc(locId)
  animations = [
    { prop=AnimProp.opacity, from=0.8, to=1.0, duration=0.6, play=true, loop=true, easing=CosineFull}
  ]
})

return function() {
  local curWarning = warningsList.value?[0]
  return {
    watch = warningsList
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    padding = [sh(0.5),sh(1)]
//    rendObj = ROBJ_WORLD_BLUR_PANEL
//    color = Color(200,200,200,200)
    children = curWarning ? warnText(curWarning) : null
  }
} 