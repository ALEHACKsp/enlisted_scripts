local fa = require("daRg/components/fontawesome.map.nut")
local { defTxtColor, activeTxtColor, bigPadding } = require("enlisted/enlist/viewConst.nut")


local textColor = @(sf) sf & S_ACTIVE ? 0xFFFFFFFF
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

local mkTextCtor = @(text) @(sf) {
  rendObj = ROBJ_DTEXT
  size = [flex(), SIZE_TO_CONTENT]
  text = text
  font = Fonts.small_text
  color = textColor(sf)
}

local function mkToggleHeader(isShow, textOrCtor) {
  local textCtor = ::type(textOrCtor) == "string" ? mkTextCtor(textOrCtor) : textOrCtor
  return ::watchElemState(@(sf) {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [bigPadding, 0, 0, 0]
    behavior = Behaviors.Button
    xmbNode = ::XmbNode()
    onClick = @() isShow(!isShow.value)
    children = [
      textCtor(sf)
      @() {
        watch = isShow
        rendObj = ROBJ_STEXT
        size = [::hdpx(25), ::hdpx(25)]
        hplace = ALIGN_CENTER
        text = isShow.value ? fa["minus-square"] : fa["plus-square"]
        font = Fonts.fontawesome
        fontSize = ::hdpx(20)
        color = textColor(sf)
        validateStaticText = false
      }
    ]
  })
}

return mkToggleHeader 