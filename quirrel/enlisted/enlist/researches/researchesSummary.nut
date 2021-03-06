local { curArmies_list } = require("enlisted/enlist/soldiers/model/state.nut")
local effectsConfig = require("enlisted/enlist/soldiers/model/config/effectsConfig.nut")
local armyEffects = require("enlisted/enlist/soldiers/model/armyEffects.nut")

local classPerksLimitByArmy = ::Computed(@()
  curArmies_list.value.reduce(function(res, armyId) {
    res[armyId] <- armyEffects.value?[armyId].max_class_level ?? {}
    return res
  }, {}))

local classWeaponUsageByArmy = ::Computed(@()
  curArmies_list.value.reduce(function(res, armyId) {
    local usageCfg = effectsConfig.value?[armyId].weapon_usage ?? {}
    local usageEff = armyEffects.value?[armyId].weapon_usage ?? {}
    res[armyId] <- usageCfg.map(function(list, sClass) {
      local usageUnlocked = usageEff?[sClass] ?? []
      return list.filter(@(tmpl) usageUnlocked.indexof(tmpl) == null)
    })
    return res
  }, {}))

local classSlotLocksByArmy = ::Computed(@()
  curArmies_list.value.reduce(function(res, armyId) {
    local unlockCfg = effectsConfig.value?[armyId].slot_unlock ?? {}
    local unlockEff = armyEffects.value?[armyId].slot_unlock ?? {}
    res[armyId] <- unlockCfg.map(function(list, sClass) {
      local slotsUnlocked = unlockEff?[sClass] ?? []
      return list.filter(@(slot) slotsUnlocked.indexof(slot) == null)
    })
    return res
  }, {}))

local upgradeLocksByArmy = ::Computed(@()
  curArmies_list.value.reduce(function(res, armyId) {
    local upgradeCfg = effectsConfig.value?[armyId].weapon_upgrades ?? []
    local upgradeEff = armyEffects.value?[armyId].weapon_upgrades ?? []
    res[armyId] <- upgradeCfg.filter(@(tmpl) upgradeEff.indexof(tmpl) == null)
    return res
  }, {}))

local upgradeCostMultByArmy = ::Computed(@()
  curArmies_list.value.reduce(function(res, armyId) {
    local discountTbl = armyEffects.value?[armyId].weapon_upgrade_discount ?? {}
    res[armyId] <- discountTbl.map(@(discount) max(0.0, 1.0 - discount))
    return res
  }, {}))

return {
  classPerksLimitByArmy = classPerksLimitByArmy
  classWeaponUsageByArmy = classWeaponUsageByArmy
  classSlotLocksByArmy = classSlotLocksByArmy
  upgradeLocksByArmy = upgradeLocksByArmy
  upgradeCostMultByArmy = upgradeCostMultByArmy
} 