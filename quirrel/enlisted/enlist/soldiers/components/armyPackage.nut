local {
  bigGap, armyIconHeight, hoverTitleTxtColor, activeTitleTxtColor
} = require("enlisted/enlist/viewConst.nut")
local armiesPresentation = require("enlisted/globals/armiesPresentation.nut")

local getImageByArmy = @(armyId, size)
  ::Picture("!ui/skin#{0}:{1}:{1}:K".subst(armiesPresentation?[armyId].icon ?? armyId, size.tointeger()))

local function mkIcon(armyId, size = armyIconHeight) {
  local image = getImageByArmy(armyId, size)
  return image != null
  ? {
      rendObj = ROBJ_IMAGE
      size = [size, size]
      image = image
      margin = bigGap
    }
  : null
}

local getArmyColor = @(selected, sf)
  (selected || (sf & S_HOVER)) ? hoverTitleTxtColor : activeTitleTxtColor

local mkName = @(armyId, isSelected = false, sf = 0) {
  rendObj = ROBJ_DTEXT
  font = Fonts.big_text
  text = ::loc(armyId)
  color = getArmyColor(isSelected, sf)
  vplace = ALIGN_CENTER
  fontFxFactor = 48
  fontFx = FFT_GLOW
  fontFxColor = Color(0, 0, 0, 100)
}

local mkArmyInfo = @(armyId, infoCtor = null) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkIcon(armyId)
    {
      flow = FLOW_VERTICAL
      margin = bigGap //same with mkIcon
      children = [
        mkName(armyId)
        infoCtor
      ]
    }
  ]
}

local mkPromoImg = @(armyId) {
  rendObj = ROBJ_SOLID
  size = [pw(100), pw(75)]
  padding = hdpx(2)
  color = Color(0,0,0)
  children = {
    rendObj = ROBJ_IMAGE
    size = flex()
    keepAspect = true
    imageValign = ALIGN_TOP
    image = ::Picture(armiesPresentation?[armyId].promoImage ?? $"ui/soldiers/{armyId}.jpg")
    fallbackImage = ::Picture("ui/soldiers/army_default.jpg")
  }
}

return {
  mkIcon = mkIcon
  mkName = mkName
  mkArmyInfo = mkArmyInfo
  mkPromoImg = mkPromoImg
}
 