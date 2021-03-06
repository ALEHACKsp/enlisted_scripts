local fpsBar = {
  rendObj = ROBJ_DTEXT
  font = Fonts.tiny_text
  behavior = Behaviors.FpsBar
  size = [sh(16), SIZE_TO_CONTENT]
  margin = [hdpx(2), hdpx(5)]
  fontFxColor = Color(0,0,0,130)
  fontFxFactor = 64
  fontFx = FFT_GLOW
  fontFxOffsX = 1
  fontFxOffsY = 1
}
local mkFpsBar = @(params) fpsBar.__merge(params)

return {mkFpsBar, fpsBar}
 