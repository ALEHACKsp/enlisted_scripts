local { sound_play } = require("sound")
local fa = require("daRg/components/fontawesome.map.nut")
local {
  smallPadding, bigPadding, perkIconSize, defTxtColor, titleTxtColor,
  noteTxtColor, soldierWndWidth
} = require("enlisted/enlist/viewConst.nut")
local scrollbar = require("daRg/components/scrollbar.nut")
local {
  perksData, getPerkPointsInfo, getRetrainingPointsText, getTierAvailableData,
  getNoAvailPerksText, showPerksChoice, buySoldierLevel, getPerksCount
} = require("model/soldierPerks.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { statusIconLocked } = require("enlisted/style/statusIcon.nut")
local { perkLevelsGrid, getNextLevelData } = require("model/perks/perksExp.nut")
local { openAvailablePerks } = require("availablePerksWnd.nut")
local perksPackage = require("components/perksPackage.nut")
local textButton = require("enlist/components/textButton.nut")
local unseenAmount = require("enlisted/enlist/components/unseenAmount.nut")
local { promoSmall } = require("enlisted/enlist/currency/pkgPremiumWidgets.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { enlistedGold } = require("enlisted/enlist/currency/currenciesList.nut")
local { mkCurrency } = require("enlisted/enlist/currency/currenciesComp.nut")
local {
  focusResearch, findResearchMaxClassLevel
} = require("enlisted/enlist/researches/researchesFocus.nut")
local { classPerksLimitByArmy } = require("enlisted/enlist/researches/researchesSummary.nut")

local slotNumber = 0

local choosePerkIcon = unseenAmount(10).__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER }) //10 to not show amount

local lockedPerkIcon = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_STEXT
  validateStaticText = false
  font = Fonts.fontawesome
  text = fa["lock"]
  color = statusIconLocked
  fontSize = hdpx(16)
}

local mkText = @(txt) {
  rendObj = ROBJ_DTEXT
  font = Fonts.small_text
  color = defTxtColor
  text = txt
}

local mkTextArea = @(txt) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  font = Fonts.small_text
  color = defTxtColor
  text = txt
}

local choosePerkRow  = @(slotIdx, icon, locId, onClick = null) perksPackage.slotBg(slotIdx, onClick, {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  padding = smallPadding
  children = [
    {
      size = [perkIconSize, perkIconSize]
      children = icon
    }
    mkTextArea(::loc(locId)).__update({
      color = titleTxtColor
    })
  ]
})

local function buySoldierLevelMsg(perks, cb) {
  local nextLevelData = getNextLevelData({
    level = perks.level
    maxLevel = perks.maxLevel
    exp = perks.exp
    lvlsCfg = perkLevelsGrid.value
  })
  if (nextLevelData == null)
    return null

  purchaseMsgBox({
    price = nextLevelData.cost
    currencyId = "EnlistedGold"
    title = ::loc("soldierLevel", { level = perks.level })
    description = ::loc("buy/soldierLevelConfirm")
    purchase = @() buySoldierLevel(perks, cb)
    srcComponent = "buy_soldier_level"
  })
}

local slotBgStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  minHeight = perkIconSize + 2 * smallPadding
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = smallPadding
}

local mkLevelCurrency = @(perks)
  function() {
    local res = { watch = perkLevelsGrid }
    local nextLevelData = getNextLevelData({
      level = perks.level
      maxLevel = perks.maxLevel
      exp = perks.exp
      lvlsCfg = perkLevelsGrid.value
    })
    return res.__update(nextLevelData != null
      ? { children = mkCurrency(enlistedGold, nextLevelData.cost) } : {})
  }

local function tierContentUi(tierIdx, tier, perks, isReachedLimit, onSlotClick, hasMonetizationValue) {
  local children = []
  local tierAvailableData = getTierAvailableData(perks, tier)
  local needShowEmpty = tierAvailableData.isSuccess
    && (perks.availPerks > 0 || (perks?.prevTier ?? -1) == perks.tiers.indexof(tier))
  local hasPurchasePerkInfoSlot = perks.availPerks <= 0 || !tierAvailableData.isSuccess
  foreach(i, p in tier.slots) {
    local perkId = p ?? ""
    if (perkId == "" && !needShowEmpty)
      continue

    local slotIdx = i
    if (perkId != "") {
      local trigger = $"tier{tierIdx}slot{slotIdx}"
      children.append(perksPackage.slot({
        perkData = { perkId = perkId }
        slotNumber = slotNumber++
        cb = (tier.choiceAmount > 0 && perks?.canChangePerk && onSlotClick)
          ? @() onSlotClick(slotIdx)
          : null
        customStyle = {
          transform = {}
          animations = [
            { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.1, play = true }
            { prop = AnimProp.translate, from = [soldierWndWidth, 0], to = [0,0],
              duration = 0.6, easing = OutCubic, trigger }
            { prop = AnimProp.opacity, from = 1, to = 0.3, duration = 0.2, delay = 0.4,
              trigger }
            { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 0.4, delay = 0.6,
              easing = Blink, trigger, onFinish = @() sound_play("ui/debriefing/squad_star") }
            { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 0.4, delay = 0.9,
              easing = Blink, trigger }
          ]
        }
      }))
      continue
    }

    if (isReachedLimit) {
      children.append(choosePerkRow(slotNumber++, lockedPerkIcon, "perk/researchClassLevel",
        @() onSlotClick ? onSlotClick(slotIdx) : null))
      hasPurchasePerkInfoSlot = false
    } else if (onSlotClick) {
      children.append(choosePerkRow(slotNumber++, choosePerkIcon, "choose_new_perk",
        @() onSlotClick(slotIdx)))
      hasPurchasePerkInfoSlot = false
    }
    needShowEmpty = false
  }

  if (hasPurchasePerkInfoSlot && children.len() < tier.slots.len()) {
    children.append(perksPackage.slotBg(slotNumber++,
      hasMonetizationValue && tierAvailableData.isSuccess
        ? @() buySoldierLevelMsg(perks, function(res) {
            if ((res?.error ?? "").len() > 0)
              return

            local chooseIdx = tier.slots.findindex(@(perkId) (perkId ?? "") == "")
            if (chooseIdx != null)
              onSlotClick(chooseIdx)
          })
        : null,
      {
        children = [
          mkTextArea(tierAvailableData.isSuccess
            ? getNoAvailPerksText(perks)
            : tierAvailableData.errorText)
              .__update({
                size = [pw(80), SIZE_TO_CONTENT]
                halign = ALIGN_CENTER
              })
          hasMonetizationValue ? mkLevelCurrency(perks) : null
        ]
      }.__update(slotBgStyle)
    ))
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = children
  }
}

local tierUi = @(tierIdx, tier, perks, isReachedLimit, onSlotClick) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    perksPackage.tierTitle(tier)
    @() {
      watch = monetization
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = tierContentUi(tierIdx, tier, perks, isReachedLimit, onSlotClick, monetization.value)
    }
  ]
}

local perksListBtn = @(soldier) {
  size = flex()
  margin = [bigPadding, 0]
  halign = ALIGN_RIGHT
  children = textButton.SmallFlat(::loc("possible_perks_list"),
    @(event) openAvailablePerks(event.targetRect, perksData.value?[soldier?.guid]),
    { margin = 0,  padding = [bigPadding, 2 * bigPadding] })
  }

local perksUi = @(soldier, canManage) function() {
  slotNumber = 0
  local soldierGuid = soldier?.guid
  local perks = perksData.value?[soldierGuid]
  local perksCount = getPerksCount(perks)
  local armyId = soldier == null ? null : getLinkedArmyName(soldier)
  local maxLevel = classPerksLimitByArmy.value?[armyId][soldier?.sClass] ?? 0
  local isReachedLimit = maxLevel > 0 && perksCount >= maxLevel
  local children = (perks?.tiers ?? [])
    .map(@(tier, tierIdx) tierUi(tierIdx, tier, perks, isReachedLimit,
      (isReachedLimit ? @(slotIdx) focusResearch(findResearchMaxClassLevel(soldier))
        : canManage ? @(slotIdx) showPerksChoice(soldier.guid, tierIdx, slotIdx)
        : null)))
    .append(perksListBtn(soldier))
  return {
    watch = [perksData, classPerksLimitByArmy]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = [bigPadding, 0]
    children = children
  }
}

local mkRetrainingPointsBtn = @(perks, hasMonetizationValue)
  perksPackage.slotBg(0,
    hasMonetizationValue ? @() buySoldierLevelMsg(perks, @(res) null) : null,
    {
      children = [
        mkTextArea(getRetrainingPointsText(perks)).__update({
          halign = ALIGN_CENTER
          color = noteTxtColor
        })
        hasMonetizationValue ? mkLevelCurrency(perks) : null
      ]
    }.__update(slotBgStyle)
  )

local mkRetrainingPoints = @(soldierGuid) function() {
  local perks = perksData.value?[soldierGuid]
  local children = perks?.canChangePerk
    ? {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_HORIZONTAL
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER

            children = [
              mkText("{0}: ".subst(::loc("perk/retraining_points")))
              mkText(perks.availPerks).__update({
                key = perks.availPerks
                font = Fonts.medium_text
                color = perks.availPerks ? titleTxtColor : defTxtColor
              })
            ]
          }
          @() {
            watch = monetization
            size = [flex(), SIZE_TO_CONTENT]
            children = mkRetrainingPointsBtn(perks, monetization.value)
          }
        ]
      }
    : null

  return {
    watch = perksData
    size = [flex(), SIZE_TO_CONTENT]
    children = children
  }
}

local function mkPerksPoints(soldier) {
  local perkPointsInfoWatch = ::Computed(function() {
    local perks = perksData.value?[soldier.guid]
    return perks == null ? null : getPerkPointsInfo(perks)
  })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    margin = [0, 0, smallPadding, 0]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = perksPackage.mkPerksPointsBlock(perkPointsInfoWatch)
  }
}

return ::kwarg(@(soldier, canManage = true) {
  flow = FLOW_VERTICAL
  size = flex()
  children = [
    canManage ? mkPerksPoints(soldier) : null
    canManage ? mkRetrainingPoints(soldier.guid) : null
    scrollbar.makeVertScroll(perksUi(soldier, canManage), { needReservePlace = false })
    @() {
      watch = monetization
      size = [flex(), SIZE_TO_CONTENT]
      children = monetization.value
        ? promoSmall("premium/buyForExperience", null, "soldier_equip", "soldier_perks")
        : null
    }
  ]
})
 