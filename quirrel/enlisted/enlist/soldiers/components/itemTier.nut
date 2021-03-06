local {smallPadding, soldierLvlColor} = require("enlisted/enlist/viewConst.nut")
local fa = require("daRg/components/fontawesome.map.nut")

return @(item) {
  hplace = ALIGN_RIGHT
  margin = smallPadding
  rendObj = ROBJ_STEXT
  validateStaticText = false
  text = array(item?.tier ?? 0, fa["star"]).reduce(@(res, val) res + val, "")
  font = Fonts.fontawesome
  fontSize = hdpx(10)
  color = soldierLvlColor
} 