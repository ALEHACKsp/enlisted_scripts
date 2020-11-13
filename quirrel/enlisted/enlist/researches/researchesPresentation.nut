const UPGRADE_TEMPLATE_SUFFIX = "_upgrade_"

local function appendSquadSize(effect, context) {
  return {
    name = "research/squad_size"
    description = "research/squad_size_desc"
    icon_id = "squad_size"
  }
}

local function appendSoldiersReserve(effect, context) {
  local reserveCount = effect?.soldiersReserve.tointeger() ?? 1
  return {
    name = $"research/plus{reserveCount}_reserve"
    description = $"research/plus{reserveCount}_reserve_desc"
    icon_id = "reserve_upgrade_icon"
  }
}

local function appendSoldierTransfer(effect, context) {
  foreach (classType, _ in effect?.soldier_transfer ?? {}) {
    return {
      name = $"research/{classType}_transfer"
      description = "research/soldier_transfer_desc"
      icon_id = "soldier_transfer_icon"
    }
  }
  return null
}

local function appendSquadXpBoost(effect, context) {
  foreach (xpBoost in effect?.squad_xp_boost ?? {}) {
    local xpBoostPercent = ((xpBoost ?? 0) * 100).tointeger()
    return {
      name = $"research/squad_xp_boost_{xpBoostPercent}"
      description = $"research/squad_xp_boost_{xpBoostPercent}_desc"
      icon_id = "squad_xp_boost_icon"
    }
  }
  return null
}

local function appendSquadClassLimit(effect, context) {
  foreach (classLimits in effect?.squad_class_limit ?? {})
    foreach (classLimitType, classLimitCount in classLimits ?? {})
      return {
        name = $"research/plus{classLimitCount}_{classLimitType}"
        description = $"research/plus{classLimitCount}_{classLimitType}_desc"
        icon_id = classLimitType
      }
  return null
}

local function appendMaxClassLevel(effect, context) {
  foreach (classType, classLevel in effect?.max_class_level ?? {}) {
    local maxClassLevel = context?.max_class_level ?? {}
    local level = (maxClassLevel?[classType] ?? 0) + classLevel
    maxClassLevel[classType] <- level
    context.max_class_level <- maxClassLevel
    return {
      name = $"research/{classType}_level{level}"
      description = "research/soldier_level_desc"
      icon_id = $"soldier_tier{level}"
    }
  }
  return null
}

local function appendMaxTrainingLevel(effect, context) {
  foreach (classType, trainingLevel in effect?.class_training ?? {}) {
    local maxTrainingLevel = context?.class_training ?? {}
    local level = (maxTrainingLevel?[classType] ?? 0) + trainingLevel
    maxTrainingLevel[classType] <- level
    context.class_training <- maxTrainingLevel
    return {
      name = $"research/{classType}_tier{level+1}"
      description = "research/soldier_tier_desc"
      icon_id = $"soldier_tier{level+1}"
    }
  }
  return null
}

local function appendSoldierDrop(effect, context) {
  foreach (soldierDrops in effect?.soldier_drop ?? {})
    foreach (soldierType, _ in soldierDrops ?? {})
      if (soldierType == "veteran_perks")
        return {
          name = "research/veteran_perks"
          description = "research/shotgunner_veteran_perks_desc"
          icon_id = "veteran_perk_icon"
        }
      else if (soldierType.indexof("tier") == 0)
        return {
          name = $"research/{soldierType}"
          description = "research/soldier_tier_desc"
          icon_id = $"soldier_{soldierType}"
        }
      else {
        local soldierTypeExt = soldierType.indexof("veteran") != null
          ? soldierType
          : $"{soldierType}_recruit" // TODO no need to add suffix, should be changed at langs
        return {
          name = $"research/{soldierTypeExt}"
          description = $"research/{soldierTypeExt}_desc"
          icon_id = soldierType
        }
      }
  return null
}

local function appendWeaponDrop(effect, context) {
  foreach (dropItem in effect?.weapon_drop ?? {})
    return {
      name = $"items/{dropItem}"
      description = "research/new_item_desc"
      gametemplate = $"{dropItem}_item"
      templateOverride = { itemPitch = -35 }
    }
  return null
}

local function appendWeaponUpgrades(effect, context) {
  foreach (upgradeTmpl in effect?.weapon_upgrades ?? []) {
    local tier = context?.templates[upgradeTmpl].tier ?? 0
    local tmplEnd = upgradeTmpl.indexof(UPGRADE_TEMPLATE_SUFFIX)
    local baseTmpl = tmplEnd != null ? upgradeTmpl.slice(0, tmplEnd) : upgradeTmpl
    return {
      name = $"research/{upgradeTmpl}"
      description = "research/upgrade_item_desc"
      gametemplate = $"{baseTmpl}_gun"
      templateOverride = { itemPitch = -35 }
      icon_id = $"soldier_tier{tier}"
      iconOverride = { scale = 0.55, pos = [0, 0.95] }
    }
  }
  return null
}

local function appendWeaponUpgradeDiscount(effect, context) {
  foreach (weaponTmpl, upgradeDiscount in effect?.weapon_upgrade_discount ?? {}) {
    local upgradeDiscountPercent = ((upgradeDiscount ?? 0) * 100).tointeger()
    return {
      name = $"research/weapon_upgrade_discount_{upgradeDiscountPercent}"
      description = $"research/{weaponTmpl}_upgrade_discount_desc"
      gametemplate = $"{weaponTmpl}_gun"
      templateOverride = { itemPitch = -35 }
      icon_id = $"weapon_upgrade_cost_icon"
      iconOverride = { scale = 0.40, pos = [0.2, 0.9] }
    }
  }
  return null
}

local function appendWeaponTuning(effect, context) {
  foreach (weaponTmpl, _ in effect?.weapon_tuning ?? {}) {
    return {
      name = $"research/weapon_tuning"
      description = $"research/{weaponTmpl}_tuning_desc"
      gametemplate = $"{weaponTmpl}_gun"
      templateOverride = { itemPitch = -35 }
      icon_id = $"veteran_perk_icon"
      iconOverride = { scale = 0.4, pos = [0.15, 0.8] }
    }
  }
  return null
}

local function appendSlotEnlarge(effect, context) {
  foreach (enlargeSlot, enlargeClasses in effect?.slot_enlarge ?? {})
    foreach (enlargeClass, enlargeCount in enlargeClasses ?? {})
      return {
        name = $"research/plus{enlargeCount}_inventoryslot"
        description = $"research/{enlargeClass}_plus{enlargeCount}_{enlargeSlot}slot_desc"
        icon_id = $"{enlargeSlot}_upgrade_icon"
      }
  return null
}

local function appendClassXpBoost(effect, context) {
  foreach (boostClass, boostValue  in effect?.class_xp_boost ?? {}) {
    local boostValuePercent = ((boostValue ?? 0) * 100).tointeger()
    return {
      name = $"research/class_xp_boost_{boostValuePercent}"
      description = $"research/{boostClass}_class_xp_boost_{boostValuePercent}_desc"
      icon_id = "class_xp_boost_icon"
    }
  }
  return null
}

local function appendSlotUnlock(effect, context) {
  foreach (slotClass, slotUnlocks in effect?.slot_unlock ?? {})
    foreach (slotType in slotUnlocks ?? [])
      return {
        name = $"research/{slotType}_slot_upgrade"
        description = $"research/{slotClass}_{slotType}_slot_upgrade_desc"
        icon_id = $"{slotType}_slot_upgrade_icon"
      }
  return null
}

local function appendVeteranClass(effect, context) {
  foreach (veteranClass, _ in effect?.veteran_class ?? {})
    return {
      name = $"research/{veteranClass}_veteran"
      description = $"research/{veteranClass}_veteran"
      icon_id = $"{veteranClass}_veteran"
    }
  return null
}

local function appendVeteranPerk(effect, context) {
  foreach (perkClass, _ in effect?.veteran_perk ?? {})
    return {
      name = $"research/{perkClass}_veteran_perk"
      description = $"research/veteran_perks_desc"
      icon_id = $"veteran_perk_icon"
    }
  return null
}

local function appendWeaponUsage(effect, context) {
  foreach (weaponClass, weaponList in effect?.weapon_usage ?? {})
    foreach (weaponTmpl in weaponList ?? [])
      return {
        name = $"items/{weaponTmpl}"
        description = $"research/{weaponClass}_weapon_usage_desc"
        gametemplate = $"{weaponTmpl}_gun"
        templateOverride = { itemPitch = -35 }
      }
  return null
}

local function appendDisassembleBonus(effect, context) {
  foreach (disasmTmpl, disasmBonus in effect?.disassemble_bonus ?? {}) {
    local disasmBonusPercent = ((disasmBonus ?? 0) * 100).tointeger()
    return {
      name = $"research/disassemble_bonus_{disasmBonusPercent}"
      description = $"research/{disasmTmpl}_disassemble_bonus_desc"
      gametemplate = $"{disasmTmpl}_gun"
      templateOverride = { itemPitch = -35 }
      icon_id = $"weapon_parts_boost_icon"
      iconOverride = { scale = 0.4, pos = [0.15, 0.85] }
    }
  }
  return null
}

local function appendVehicleUsage(effect, context) {
  foreach (vehicleList in effect?.vehicle_usage ?? {})
    foreach (vehicleTmpl in vehicleList ?? [])
      return {
        name = $"vehicleDetails/{vehicleTmpl}"
        description = $"research/vehicle_usage_desc"
        gametemplate = $"{vehicleTmpl}"
        templateOverride = { scale = 1.15 }
      }
  return null
}

local RESEARCH_DATA_APPENDERS = {
  squad_size = appendSquadSize
  soldiersReserve = appendSoldiersReserve
  soldier_transfer = appendSoldierTransfer
  squad_xp_boost = appendSquadXpBoost
  squad_class_limit = appendSquadClassLimit
  max_class_level = appendMaxClassLevel
  class_training = appendMaxTrainingLevel
  soldier_drop = appendSoldierDrop
  weapon_drop = appendWeaponDrop
  weapon_upgrades = appendWeaponUpgrades
  weapon_upgrade_discount = appendWeaponUpgradeDiscount
  weapon_tuning = appendWeaponTuning
  slot_enlarge = appendSlotEnlarge
  class_xp_boost = appendClassXpBoost
  slot_unlock = appendSlotUnlock
  veteran_class = appendVeteranClass
  veteran_perk = appendVeteranPerk
  weapon_usage = appendWeaponUsage
  disassemble_bonus = appendDisassembleBonus
  vehicle_usage = appendVehicleUsage
}

local function prepareResearch(research, context) {
  // cleanup effects table
  local effect = (research?.effect ?? {}).filter(@(val) (val?.len() ?? val ?? 0) != 0)
  research = research.__merge({ effect = effect })
  foreach (effectId, appender in RESEARCH_DATA_APPENDERS)
    if (effectId in effect) {
      research.__update(appender(effect, context) ?? {})
      break
    }
  return research
}

return prepareResearch 