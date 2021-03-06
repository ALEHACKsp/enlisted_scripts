local style = require("ui/hud/style.nut")

local function text(txt, params={}) {
  if (::type(text)=="table")
    txt = params?.text ?? ""
  return {
    size = [flex(), SIZE_TO_CONTENT]
    font = Fonts.big_text
    color = style.DEFAULT_TEXT_COLOR
  }.__update(params).__update({
    rendObj=ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text=txt
  })
}

return text 