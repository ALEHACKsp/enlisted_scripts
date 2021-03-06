local style = require("ui/hud/style.nut")

local function text(txt, params={}) {
  return {
    rendObj = ROBJ_DTEXT
    margin = hdpx(2)
    font = Fonts.big_text
    color = style.DEFAULT_TEXT_COLOR
    text = txt
  }.__update(params)
}

return text 