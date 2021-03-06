local fa = require("daRg/components/fontawesome.map.nut")
local {
  msgHighlightedTxtColor, soldierLvlColor, smallPadding, hoverTxtColor
} = require("enlisted/enlist/viewConst.nut")
local {
  statusIconChosen, statusIconDisabled, statusIconLocked
} =  require("enlisted/style/statusIcon.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")

local mkStatusIcon = @(icon, color) {
  margin = smallPadding
  rendObj = ROBJ_STEXT
  validateStaticText = false
  font = Fonts.fontawesome
  fontSize = hdpx(15)
  text = fa[icon]
  color = color
}

local iconChosen = mkStatusIcon("check", statusIconChosen)
local iconBlocked = mkStatusIcon("ban", statusIconDisabled)

local mkBackBlock = @(children) {
  rendObj = ROBJ_BOX
  size = array(2, ::hdpx(19))
  borderWidth = 0
  borderRadius = ::hdpx(5)
  fillColor = statusIconLocked
  clipChildren = true
  margin = smallPadding
  valign = ALIGN_CENTER
  children = children
}

local iconLocked = mkBackBlock({
  rendObj = ROBJ_STEXT
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  validateStaticText = false
  font = Fonts.fontawesome
  fontSize = hdpx(11)
  text = fa["lock"]
  color = hoverTxtColor
  pos = [::hdpx(1), ::hdpx(1)]
})

local mkLevelBlock = @(level) mkBackBlock({
  rendObj = ROBJ_DTEXT
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  text = level
  font = Fonts.tiny_text
  color = hoverTxtColor
})

local statusIconCtor = @(demands) demands?.classLimit != null ? iconBlocked
  : demands == null ? null
  : iconLocked

local mkHintText = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  font = Fonts.small_text
  text = text
  color = msgHighlightedTxtColor
}

local mkStatusHint = @(demands) demands == null ? null
  : demands?.classLimit != null ? mkHintText(::loc("itemClassResearch", {
      soldierClass = ::loc(soldierClasses?[demands.classLimit].locId ?? "unknown")
    }))
  : demands?.levelLimit != null ? mkHintText(::loc("itemObtainAtLevel", {
      level = demands.levelLimit
    }))
  : mkHintText(::loc(demands?.canObtainInShop ? "itemObtainInShop" : "itemOutOfStock"))

local mkTierBlock = @(item) (item?.tier ?? 0) < 1 ? null : {
    rendObj = ROBJ_STEXT
    margin = smallPadding
    validateStaticText = false
    text = "".join(array(item.tier, fa["star"]))
    font = Fonts.fontawesome
    fontSize = hdpx(10)
    color = soldierLvlColor
  }

return {
  statusIconLocked = iconLocked
  statusIconChosen = iconChosen
  statusIconBlocked = iconBlocked
  statusIconCtor = statusIconCtor
  statusLevel = mkLevelBlock
  statusTier = mkTierBlock
  hintText = mkHintText
  statusHintText = mkStatusHint
} 