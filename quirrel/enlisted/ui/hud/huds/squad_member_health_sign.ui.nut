local fa = require("daRg/components/fontawesome.map.nut")

local colorBleeding = Color(200,50,50)
local colorWounded = Color(200,100,100)

local healthSign = @(ratio) {
  rendObj = ROBJ_STEXT
  padding = hdpx(2)
  validateStaticText = false
  text = (ratio < 0.3) ? $"{fa["tint"]}{fa["tint"]}" : (ratio < 0.75) ? fa["tint"] : ""
  color = (ratio < 0.3) ? colorBleeding : (ratio < 0.75) ? colorWounded : 0
  font = Fonts.fontawesome
  fontSize = hdpx(10)
}

local memberHpBlock = @(member)
  member.hp <= 0 || member.maxHp <= 0 || (member.hp >= member.maxHp * 0.75)
    ? null
    : {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        children = healthSign(member.hp / member.maxHp)
      }


return memberHpBlock
 