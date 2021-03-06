local fa = require("daRg/components/fontawesome.map.nut")
return ::kwarg(function mkSpinner(height=hdpx(80), opacity=0.3, color=Color(255,255,255), duration=1, key=null){
  return {
    size = [height, height]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      key = key
      text = fa["spinner"]
      rendObj = ROBJ_STEXT
      validateStaticText = false
      color = color
      fontSize = height/2
      opacity = opacity
      font = Fonts.fontawesome
      transform = {}
      animations = [
        { prop = AnimProp.rotate, from = 0, to = 360, duration = duration, play = true, loop = true, easing = Discrete8 }
      ]
    }
  }
})
 