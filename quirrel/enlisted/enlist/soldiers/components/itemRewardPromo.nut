local soldierItemTypeIcon = require("soldierItemTypeIcon.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")

local { Purchase } = require("enlist/components/textButton.nut")
local { textMargin } = require("daRg/components/textButton.style.nut")
local { txt, noteTextArea } = require("enlisted/enlist/components/defcomps.nut")
local {
  bigPadding, darkBgColor, lockedSquadBgColor, activeTxtColor, squadElemsBgColor,
  unlockedSquadBgColor, smallPadding
} = require("enlisted/enlist/viewConst.nut")

local {
  allItemTemplates, findItemTemplate
} = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local {
  getItemName, getItemDesc, getItemTypeName
} = require("enlisted/enlist/soldiers/itemsInfo.nut")

local headHeight = (sh(6) + 2 * bigPadding).tointeger()

local lockedOverBlock = @(unlock) function() {
  local res = { watch = unlock }
  if (unlock.value == null)
    return res
  return res.__update({
    rendObj = ROBJ_SOLID
    size = [pw(100), pw(75)]
    color = Color(0,0,0)
    opacity = 0.5
  })
}

local mkItemRewardHead = @(iType, iName, itemType, itemSubType) {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    {
      rendObj = ROBJ_SOLID
      size = [flex(), headHeight]
      color = darkBgColor
    }
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      padding = bigPadding
      children = [
        soldierItemTypeIcon({ itemType, itemSubType, size = ::hdpx(100) })
        {
          size = [flex(), sh(6)]
          flow = FLOW_VERTICAL
          children = [
            txt({
              text = iType
              font = Fonts.big_text
            })
            { size = flex() }
            txt({
              text = iName
              font = Fonts.big_text
              color = Color(200,150,100)
            })
          ]
        }
      ]
    }
  ]
}

local mkSquadSummary = @(descLocId) {
  rendObj = ROBJ_SOLID
  size = [flex(), ::hdpx(120)]
  color = ::Color(40, 40, 40, 255)
  children = (descLocId ?? "").len() > 0
    ? noteTextArea(::loc(descLocId, "")).__update({
        margin = bigPadding
        color = activeTxtColor
        font = Fonts.small_text
      })
    : null
}

local mkUnlockInfo = @(t) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  margin = hdpx(1)
  halign = ALIGN_CENTER
  color = lockedSquadBgColor
  children = txt({
    text = t
    font = Fonts.medium_text
    color = activeTxtColor
  })
}

local mkUnlockCount = @(count) {
  rendObj = ROBJ_BOX
  size = [::hdpx(90), ::hdpx(90)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = darkBgColor
  borderWidth = ::hdpx(2)
  borderColor = squadElemsBgColor
  children = txt({
    text = ::loc("common/amountShort", { count = count })
    font = Fonts.big_text
  })
}

local function mkUnlockDescription(itemTpl) {
  local desc = getItemDesc(itemTpl)
  if (desc == "")
    return { size = flex() }
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), ::hdpx(90)]
    color = squadElemsBgColor
    valign = ALIGN_CENTER
    padding = [0, bigPadding * 2]
    children = noteTextArea(desc).__update({
      font = Fonts.small_text
    })
  }
}

local mkUnlockContent = @(itemTpl, count) {
  size = [pw(60), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  margin = [0, bigPadding]
  children = [
    mkUnlockCount((count ?? "") == "" ? 1 : count)
    mkUnlockDescription(itemTpl)
  ]
}

local mkUnlockBlock = @(unlockInfo) function() {
  local res = {
    watch = unlockInfo
    size = [flex(), SIZE_TO_CONTENT]
    padding = bigPadding
  }

  local unlock = unlockInfo.value
  if (unlock == null)
    return res.__update({
      children = mkUnlockInfo(::loc("squad/unlocked")).__update({
        color = unlockedSquadBgColor
        padding = textMargin
      })
    })
  if (unlock?.unlockCb != null)
    return res.__update({
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_RIGHT
        children = [
          Purchase(::loc("mainmenu/unlockNow"), unlock.unlockCb, {
            size = [flex(), SIZE_TO_CONTENT]
            margin = hdpx(1)
            animations = [{
              prop = AnimProp.opacity, from = 0.7, to = 1, duration = 1,
              play = true, loop = true, easing = Blink
            }]
          })
          unseenSignal(0.8)
        ]
      }
    })
  return res.__update({
    children = mkUnlockInfo(unlock?.unlockText ?? "").__update({
      padding = textMargin
    })
  })
}

local mkBgImg = @(img) {
  rendObj = ROBJ_IMAGE
  size = flex()
  keepAspect = true
  imageValign = ALIGN_TOP
  image = ::Picture(img)
}

local mkBackWithImage = @(img) {
  rendObj = ROBJ_SOLID
  size = [pw(100), pw(75)]
  margin = [headHeight, 0,0,0]
  color = Color(0,0,0)
  children = img != null ? mkBgImg(img) : null
}

local mkItemPromo = ::kwarg(function(armyId, itemTpl, countText, presentation, unlockInfo) {
  local item = findItemTemplate(allItemTemplates, armyId, itemTpl)
  if (item == null)
    return null

  return {
    size = flex()
    padding = ::hdpx(1)
    clipChildren = true
    children = [
      mkBackWithImage(presentation?.image)
      lockedOverBlock(unlockInfo)
      {
        size = flex()
        flow = FLOW_VERTICAL
        margin = [headHeight, 0, 0, 0]
        children = [
          { size = flex() }
          mkUnlockContent(itemTpl, countText)
          mkUnlockBlock(unlockInfo)
          mkSquadSummary(presentation?.summaryLocId)
        ]
      }
      mkItemRewardHead(getItemTypeName(item), getItemName(item), item.itemtype, item.itemsubtype)
    ]
  }
})

return mkItemPromo
 