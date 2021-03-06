local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")
return @(scale = 1, iconColor = colors.UnseenIcon) {
  size = [hdpx(32 * scale), hdpx(32 *scale)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_STEXT
  validateStaticText = false
  font = Fonts.fontawesome
  text = fa["exclamation-circle"]
  fontSize = hdpx(16 * scale)
  fontFxColor = colors.UnseenGlow
  fontFxFactor = 64
  fontFx = FFT_GLOW
  color = iconColor
  animations = [ { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1, play = true, loop = true, easing = Blink} ]
} 