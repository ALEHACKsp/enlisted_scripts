local colorize = require("enlist/colorize.nut")
local mkSoldierCard = require("mkSoldierCard.nut")
local { round_by_value } = require("std/math.nut")
local { mkSoldiersData } = require("model/collectSoldierData.nut")
local {txt} = require("enlisted/enlist/components/defcomps.nut")
local {promoSmall} = require("enlisted/enlist/currency/pkgPremiumWidgets.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local {
  perkPointCostText, perkPointIcon
} = require("components/perksPackage.nut")
local sClassesCfg = require("model/config/sClassesConfig.nut")
local { pPointsBaseParams, pPointsList } = require("model/perks/perksPoints.nut")
local {
  bigPadding, slotBaseSize, defBgColor, defTxtColor, titleTxtColor
} = require("enlisted/enlist/viewConst.nut")
local { sound_play } = require("sound")


local mkEmptySoldierSlot = @() {
  rendObj = ROBJ_SOLID
  size = slotBaseSize
  color = defBgColor
}

local mkChoosedSoldierSlot = ::kwarg(function(soldier, idx, onClickCb) {
  local stateFlags = ::Watched(0)
  local group = ::ElemGroup()
  local soldierData = mkSoldiersData(soldier)
  return @() {
    watch = [stateFlags, soldierData]
    behavior = Behaviors.Button
    group = group
    onElemState = @(sf) stateFlags(sf)
    onClick = @() onClickCb(soldier)
    children = mkSoldierCard({
      idx = idx
      soldierInfo = soldierData.value
      sf = stateFlags.value
      group = group
    })
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.2, play = true }
      { trigger = $"{soldier.guid}", prop = AnimProp.translate, from = [-sh(15),-sh(10)], to = [0,0], duration = 0.5, easing = OutQuart }
      { trigger = $"{soldier.guid}", prop = AnimProp.scale, from = [2,2], to = [1,1], duration = 0.5, easing = InOutCubic}
      { trigger = $"{soldier.guid}", prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, easing = InOutCubic}
    ]
  }
})

local mkChoiseBlock = function(choosenSoldiers, onSlotClickCb) {
  local getChosenCount = @() choosenSoldiers.value.filter(@(s) s != null).len()
  local prevChosenCount = getChosenCount()
  return function(){
    local curChosenCount = getChosenCount()
    if (curChosenCount > prevChosenCount)
      sound_play("ui/academy_send")
    prevChosenCount = curChosenCount
    return {
      watch = choosenSoldiers
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = choosenSoldiers.value.map(@(soldier, idx)
        soldier == null
          ? mkEmptySoldierSlot()
          : mkChoosedSoldierSlot({
              soldier = soldier
              idx = idx
              onClickCb = onSlotClickCb
            })
      )
    }
  }
}

local blockDesc = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  color = defTxtColor
  text = ::loc("retraining/desc")
}

local resultBlock = @(choosenSoldiers)
  function() {
    local res = {watch = choosenSoldiers}
    local sClass
    local sClasses = {}
    local maxLevel = 1
    local tier = 1
    local totalChosen = 0
    local pPointsData = {}
    foreach (soldier in choosenSoldiers.value) {
      if (soldier == null)
        continue

      sClass = soldier.sClass
      sClasses[sClass] <- (sClasses?[sClass] ?? 0) + 1
      totalChosen++

      maxLevel = soldier.maxLevel + 1
      tier = soldier.tier + 1

      local sClassRare = soldier.sClassRare
      local classCfg = sClassesCfg.value?[sClass]
      local modifications = classCfg?.perkPointsModifications[sClassRare]
      local perkPointParams = classCfg?.pointsByTiers[tier]
      if (modifications != null && perkPointParams != null)
        foreach (pPointId in pPointsList) {
          if (pPointId not in pPointsData)
            pPointsData[pPointId] <- {
              minVal = (perkPointParams?[pPointId].min ?? 0) + (modifications?[pPointId] ?? 0)
              maxVal = (perkPointParams?[pPointId].max ?? 0) + (modifications?[pPointId] ?? 0)
            }
          else {
            pPointsData[pPointId].minVal = ::min(pPointsData[pPointId].minVal,
              (perkPointParams?[pPointId].min ?? 0) + (modifications?[pPointId] ?? 0))
            pPointsData[pPointId].maxVal = ::max(pPointsData[pPointId].maxVal,
              (perkPointParams?[pPointId].max ?? 0) + (modifications?[pPointId] ?? 0))
          }
        }
    }

    local hasClassIcon = sClasses.len() == 1
    local customClassTooltip = null
    if (!hasClassIcon) {
      customClassTooltip = ""
      foreach (classId, val in sClasses)
        customClassTooltip = "{0}{1}{2}".subst(customClassTooltip,
          ::loc("retraining/classChance", {
            sClass = colorize(titleTxtColor, ::loc($"soldierClass/{classId}"))
            chance = totalChosen < 1 ? 0 : round_by_value(100.0 * val / totalChosen, 0.01)
          }), "\n")
    }

    return pPointsData.len() > 0
      ? res.__update({
          flow = FLOW_VERTICAL
          children = [
            txt({
              text = ::loc("retraining/expectedResult")
              hplace = ALIGN_CENTER
              margin = bigPadding
            })
            mkSoldierCard({
              soldierInfo = {
                guid = ""
                level = 1
                perksCount = 1
                tier = tier
                maxLevel = maxLevel
                sClass = hasClassIcon ? sClass : null
                customClassTooltip = customClassTooltip
              }
              addChild = @(...) {
                flow = FLOW_HORIZONTAL
                children = pPointsList.map(function(pPointId) {
                  local pPointCfg = pPointsBaseParams[pPointId]
                  local minVal = pPointsData?[pPointId].minVal ?? 0
                  local maxVal = pPointsData?[pPointId].maxVal ?? 0
                  local valText = minVal == maxVal ? maxVal : $"{minVal}-{maxVal}"
                  return {
                    flow = FLOW_HORIZONTAL
                    valign = ALIGN_CENTER
                    children = [
                      perkPointCostText(pPointCfg, valText)
                      perkPointIcon(pPointCfg)
                    ]
                  }
                })
              }
            })
          ]
        })
      : res
  }

local mkTrainingBlock = @(choosenSoldiers, onSlotClickCb, navBlock) {
  size = flex()
  flow = FLOW_VERTICAL
  padding = bigPadding
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = sh(2)
      halign = ALIGN_CENTER
      children = [
        txt({ text = ::loc("retraining/title"), font = Fonts.medium_text })
        blockDesc.__merge({ text = ::loc("retraining/info") })
        mkChoiseBlock(choosenSoldiers, onSlotClickCb)
        resultBlock(choosenSoldiers)
        blockDesc
        navBlock
        @() {
          watch = monetization
          size = flex()
          margin = [0, bigPadding]
          valign = ALIGN_BOTTOM
          children = monetization.value
            ? promoSmall("premium/buyForTrainSpeed", {
                rendObj = ROBJ_SOLID
                color = defBgColor
                padding = bigPadding
              }, null, "training_controls")
            : null
        }
      ]
    }
  ]
}

return ::kwarg(mkTrainingBlock)
 