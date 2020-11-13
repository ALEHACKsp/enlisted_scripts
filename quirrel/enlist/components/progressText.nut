local function progressText(text) {
  return {
    rendObj = ROBJ_DTEXT
    text = text
    font = Fonts.big_text
    key = text

    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER

    animations = [
      {
        prop=AnimProp.color, from=Color(255,255,250), to=Color(220,255,120), easing=CosineFull,
        duration=0.8, loop=true, play=true
      }
    ]
  }
}


return progressText
 