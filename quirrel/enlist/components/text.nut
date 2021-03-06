local function header1(text) {
  return {
    rendObj = ROBJ_DTEXT
    size = [flex(), SIZE_TO_CONTENT]
    font = Fonts.big_text
    text = text
    margin = [0,0,sh(2),0]
  }
}


local function header2(text) {
  return {
    rendObj = ROBJ_DTEXT
    size = [flex(), SIZE_TO_CONTENT]
    font = Fonts.medium_text
    text = text
    margin = [0,0,sh(1),0]
  }
}


local function textarea(text) {
  return {
    rendObj = ROBJ_TEXTAREA
    size = [sw(35), SIZE_TO_CONTENT]
    behavior = Behaviors.TextArea
    text = text
    margin = [0,0,sh(2),0]
  }
}



return {
  h1 = header1
  h2 = header2
  textarea = textarea
} 