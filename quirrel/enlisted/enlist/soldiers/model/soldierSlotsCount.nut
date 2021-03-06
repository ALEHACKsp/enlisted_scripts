local { configs } = require("enlisted/enlist/configs/configs.nut")
local { perksData, getTotalPerkValue } = require("soldierPerks.nut")
local { curCampSoldiers } = require("state.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local effectsConfig = require("config/effectsConfig.nut")
local armyEffects = require("armyEffects.nut")

local slotTypeToPerk = ::Computed(@() configs.value?.perks.slotCountPerks ?? {})

local function soldierSlotsCount(soldierGuid, equipScheme) {
  local baseSlots = equipScheme.map(@(s) s?.listSize ?? 0)
    .filter(@(s) s > 0)
  if (baseSlots.len() == 0)
    return ::Watched({})
  return ::Computed(function() {
    local perks = perksData.value?[soldierGuid]
    local modSlots = baseSlots.map(@(val, slotType) slotType in slotTypeToPerk.value
      ? val + getTotalPerkValue(perks, slotTypeToPerk.value?[slotType]).tointeger()
      : val)
    local soldier = curCampSoldiers.value?[soldierGuid]
    if (soldier != null) {
      local sClass = soldier?.sClass
      local effects = armyEffects.value?[getLinkedArmyName(soldier)].slot_enlarge ?? {}
      modSlots = modSlots.map(@(val, slotType) val + (effects?[slotType][sClass] ?? 0))
    }
    return modSlots
  })
}

local function soldierSlotsLocked(soldierGuid, equipScheme) {
  return ::Computed(function() {
    local soldier = curCampSoldiers.value?[soldierGuid]
    if (soldier != null) {
      local armyId = getLinkedArmyName(soldier)
      local sClass = soldier?.sClass
      local effects = armyEffects.value?[armyId].slot_enlarge ?? {}
      local researches = effectsConfig.value?[armyId].slot_enlarge ?? {}
      equipScheme = equipScheme.map(@(_, slotType)
        max(0, (researches?[slotType][sClass] ?? 0) - (effects?[slotType][sClass] ?? 0)))
    }
    return equipScheme
  })
}

return {
  soldierSlotsCount
  soldierSlotsLocked
} 