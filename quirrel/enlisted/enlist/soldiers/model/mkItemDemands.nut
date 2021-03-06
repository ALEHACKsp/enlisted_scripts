local { classWeaponUsageByArmy } = require("enlisted/enlist/researches/researchesSummary.nut")
local { armies, curArmy } = require("state.nut")
local { getCratesListItemsComp } = require("cratesContent.nut")
local { curArmyShopCrates } = require("enlisted/enlist/shop/armyShopState.nut")

local function getDemandsFromPool(pool, key, value) {
  local byKey = pool?[key] ?? {}
  pool[key] <- byKey
  local byValue = byKey?[value] ?? { [key] = value }
  byKey[value] <- byValue
  return byValue
}

// Caveat: This method will only work correctly for items demands check of the currently selected army
local function mkItemListDemands(items, sClass = null) {
  if (typeof items != "array")
    items = [items]
  local curCrates = getCratesListItemsComp(curArmy, curArmyShopCrates)
  local demandsPool = {}
  return ::Computed(function() {
    local armyId = curArmy.value
    local armyLevel = armies.value?[armyId].level ?? 0
    local usageLocked = classWeaponUsageByArmy.value?[armyId][sClass]
    return items.map(function(item) {
      local { basetpl = null, unlocklevel = 0 } = item
      if (!(item?.isShopItem ?? false))
        return usageLocked?.indexof(basetpl) != null
          ? {
              item
              demands = getDemandsFromPool(demandsPool, "classLimit", sClass)
            }
          : { item }
      if (unlocklevel > 0 && unlocklevel > armyLevel)
        return {
          item
          demands = getDemandsFromPool(demandsPool, "levelLimit", unlocklevel)
        }
      return {
        item
        demands = getDemandsFromPool(demandsPool, "canObtainInShop", basetpl in curCrates.value)
      }
    })
  })
}

local function mkItemDemands(item, sClass = null) {
  local demands = mkItemListDemands(item, sClass)
  return ::Computed(@() demands.value?[0].demands)
}

return {
  mkItemDemands
  mkItemListDemands
} 