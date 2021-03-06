local {
  defTxtColor, textBgBlurColor, detailsHeaderColor, smallPadding, bigPadding,
  inventoryItemDetailsWidth
} = require("enlisted/enlist/viewConst.nut")
local { statusTier, statusHintText, statusIconCtor } = require("itemPkg.nut")
local { mkItemDemands } = require("enlisted/enlist/soldiers/model/mkItemDemands.nut")
local { getItemName, getItemDesc } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { itemPartsAmountCtor } = require("modifyItemComp.nut")
local { blur, mkDetails, mkUpgrades } = require("itemDetailsPkg.nut")

local animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, easing = OutCubic,
    play = true, trigger = "itemDetailsAnim"}
  { prop = AnimProp.translate, from =[0, hdpx(100)], to = [0, 0], duration = 0.15, easing = OutQuad,
    play = true, trigger = "itemDetailsAnim"}
]

local lockedInfo = @(item, soldierWatch) function() {
  local demandsWatch = mkItemDemands(item, soldierWatch.value?.sClass)
  local watches = { watch = [demandsWatch, soldierWatch] }
  local demands = demandsWatch.value
  if (demands == null)
    return blur({
      rendObj = ROBJ_DTEXT
      maxWidth = inventoryItemDetailsWidth
      halign = ALIGN_RIGHT
      text = ::loc("itemCurrentCount", { count = item?.count ?? 0 })
      font = Fonts.small_text
      color = defTxtColor
    }).__update(watches)
  return blur([
    statusHintText(demands)
    statusIconCtor(demands)
  ]).__update({
    watch = soldierWatch
    size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
  })
}


local lastTpl = null
local mkItemDetails = @(viewItemWatch, soldierWatch) function() {
  local res = {
    watch = viewItemWatch
    transform = {}
    animations = animations
  }
  local item = viewItemWatch.value
  local tpl = item?.basetpl
  if (lastTpl != tpl) {
    lastTpl = tpl
    ::anim_start("itemDetailsAnim")
  }
  if (!tpl)
    return res

  local descLoc = getItemDesc(item)
  return res.__update({
    size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = smallPadding
    children = [
      blur({
        maxWidth = inventoryItemDetailsWidth
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_RIGHT
        font = Fonts.medium_text
        text = getItemName(item)
        color = detailsHeaderColor
      })
      item?.tier ? blur(statusTier(item)) : null
      lockedInfo(item, soldierWatch)
      descLoc == "" ? null : blur({
        maxWidth = inventoryItemDetailsWidth
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        halign = ALIGN_RIGHT
        text = descLoc
        font = Fonts.small_text
        color = defTxtColor
      })
      mkDetails(item)
      mkUpgrades(item)
    ]
  })
}

local animScale = {
  prop=AnimProp.scale, trigger="modifyInfo", easing=InOutCubic
}
local animMove = {
  prop=AnimProp.translate, trigger="modifyInfo", easing=InOutCubic
}

local mkModifyInfo = @(itemPartsCount) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  padding = bigPadding
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_DTEXT
      color = defTxtColor
      text = ::loc("itemParts/amountInfo")
      transform = {pivot = [1, 0.5]}
      animations = [
        animMove.__merge({ from=[0,0],         to=[hdpx(-70),0], duration=1 })
        animMove.__merge({ from=[hdpx(-70),0], to=[hdpx(-70),0], duration=0.3, delay=0.9 })
        animMove.__merge({ from=[hdpx(-70),0], to=[1,1],         duration=0.5, delay=1.1 })
      ]
    }
    itemPartsAmountCtor(itemPartsCount)(null, null, null, null, 0, true)
      .__update({
        transform = {pivot = [1, 0.5]}
        animations = [
          animScale.__merge({ from=[1,1],     to=[1.5,1.5], duration=0.7 })
          animScale.__merge({ from=[1.5,1.5], to=[1.5,1.5], duration=0.5, delay=0.6 })
          animScale.__merge({ from=[1.5,1.5], to=[1,1],     duration=0.3, delay=1 })
        ]
      })
  ]
}

return {
  mkItemDetails
  mkModifyInfo
}
 