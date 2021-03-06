local fa = require("daRg/components/fontawesome.map.nut")
local colors = require("ui/style/colors.nut")
return function(amount = 1) {
  if (amount < 1)
    return {}
  local needCounter = amount < 10
  return {
    size = [hdpx(32), hdpx(32)]
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_STEXT
    validateStaticText = false
    font = Fonts.fontawesome
    text = needCounter ? fa["circle"] : fa["exclamation-circle"]
    color = colors.UnseenIcon
    fontSize = hdpx(16)
    fontFxColor = colors.UnseenGlow
    fontFxFactor = 64
    fontFx = FFT_GLOW

    animations = [ { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1, play = true, loop = true, easing = Blink} ]

    children = needCounter
      ? {
          rendObj = ROBJ_DTEXT
          font = Fonts.small_text
          color = 0xFF000000
          text = amount
          pos = [0, hdpx(-1)] //more correct center text visualy
        }
      : null
  }
} 