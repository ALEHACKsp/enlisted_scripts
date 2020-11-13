local function centeredText(text, options={}) {
  return {
    rendObj = ROBJ_DTEXT
    text = text
    font = Fonts.big_text
    key = options?.key ?? text

    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }
}


return centeredText
 