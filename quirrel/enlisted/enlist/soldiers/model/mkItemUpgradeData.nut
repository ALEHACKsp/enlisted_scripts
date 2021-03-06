local { ceil } = require("std/math.nut")
local { mkItemPartsNumberComp, getModifyItemGuid } = require("selectItemState.nut")
local itemsModifyConfig = require("enlisted/enlist/soldiers/model/config/itemsModifyConfig.nut")
local {
    upgradeLocksByArmy, upgradeCostMultByArmy
  } = require("enlisted/enlist/researches/researchesSummary.nut")
local { maxCampaignLevel } = require("enlisted/enlist/soldiers/model/state.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")

const MODIFY_ITEM_REQ_LVL = 3

local canModifyItems = ::Computed(@() maxCampaignLevel.value >= MODIFY_ITEM_REQ_LVL)

local canUpgrade = @(item)
   (item?.guid ?? "") != "" && (item?.upgradeitem ?? "").len() > 0

local mkItemUpgradeData = function(item){

  if (!canUpgrade(item))
    return ::Computed(@(){ isUpgradable = false })

  local itemParts = mkItemPartsNumberComp(item)
  local armyId = getLinkedArmyName(item)
  return ::Computed(function(){
    local res = {
      isUpgradable = false
      isResearchRequired = false
      armyId = armyId
      hasEnoughParts = false
      partsRequired = 0
      modifyData = null
      upgradeMult = null
      itemBaseTpl = item?.basetpl
      iGuid = null
    }

    local modifyData = itemsModifyConfig.value?[item?.tier ?? 0]
    if (modifyData == null || !canModifyItems.value)
      return res

    res.isUpgradable = true

    local lockedUpgrades = upgradeLocksByArmy.value?[armyId] ?? []
    if (lockedUpgrades.indexof(item?.upgradeitem) != null)
        return res.__update({ isResearchRequired = true })

    local itemBaseTpl = item?.basetpl
    local upgradeMult = upgradeCostMultByArmy.value?[armyId][itemBaseTpl] ?? 1.0
    local partsRequired = ceil(modifyData.upgradeRequired * upgradeMult).tointeger()
    local iGuid = getModifyItemGuid(item, true)
    local hasEnoughParts = !(iGuid == null || itemParts.value < partsRequired)
    return res.__update({ modifyData, iGuid, upgradeMult, itemBaseTpl, partsRequired, hasEnoughParts })
  })
}

return mkItemUpgradeData 