local fa = require("daRg/components/fontawesome.map.nut")
local defcomps = require("enlisted/enlist/components/defcomps.nut")
local style = require("enlisted/enlist/viewConst.nut")

local function blinkingIcon(iconId, text = null, isSelected = false) {
  local color = isSelected ? style.blinkingSignalsGreenDark : style.blinkingSignalsGreenNormal
  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [hdpx(2), hdpx(3), 0, 0]
    gap = hdpx(1)
    transform = {}
    animations = [ { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 1, play = true, loop = true, easing = Blink } ]
    children = [
      {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        validateStaticText = false
        text = fa[iconId]
        fontSize = hdpx(11)
        color = color
      }
      text != null ? defcomps.note({ text = text, color = color }) : null
    ]
  }
}

return blinkingIcon 