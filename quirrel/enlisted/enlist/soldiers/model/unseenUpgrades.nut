local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local itemsModifyConfig = require("config/itemsModifyConfig.nut")
local { ceil } = require("std/math.nut")
local { allItemTemplates } = require("all_items_templates.nut")

local {
  curArmiesList, itemsByArmies, soldiersByArmies
} = require("enlisted/enlist/meta/profile.nut")
local {
  itemCountByArmy, curArmy, chosenSquadsByArmy
} = require("state.nut")
local {
  upgradeCostMultByArmy
} = require("enlisted/enlist/researches/researchesSummary.nut")
local {
  getLinkedSquadGuid, getItemIndex
} = require("enlisted/enlist/meta/metalink.nut")


const SEEN_ID = "seen/upgrades"

local seen = ::Computed(@() settings.value?[SEEN_ID])
local ignoreSlots = { secondary = true }

local function markSeenUpdates(armyId, iGuidsList) {
  local seenUpdates = seen.value?[armyId] ?? {}
  local filtered = iGuidsList.filter(@(name) name not in seenUpdates)
  if (filtered.len() == 0)
    return

  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local updatesSaved = clone (saved?[armyId] ?? {})
    filtered.each(@(name) updatesSaved[name] <- true)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

local function markUnseenUpdates(armyId, iGuidsList) {
  local seenUpdates = seen.value?[armyId] ?? {}
  local filtered = iGuidsList.filter(@(name) name in seenUpdates)
  if (filtered.len() == 0)
    return

  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local updatesSaved = (saved?[armyId] ?? {})
      .filter(@(v, name) filtered.findindex(@(v) v == name) == null)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

local function updateSeen(armyId, availableUpgrades) {
  local seenUpdates = seen.value?[armyId] ?? {}
  if (seenUpdates.len() == 0)
    return

  local filtered = seenUpdates.filter(@(name) name not in availableUpgrades).keys()
  if (filtered.len() == 0)
    return

  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local updatesSaved = (saved?[armyId] ?? {})
      .filter(@(v, name) filtered.findindex(@(v) v == name) == null)
    saved[armyId] <- updatesSaved
    set[SEEN_ID] <- saved
  })
}

local function getEquipInfoByItem(item, curSoldiers) {
  local links = item?.links ?? {}
  if (links.len() <= 1)
    return null

  foreach (link, linkType in links)
    if (link in curSoldiers && (linkType not in ignoreSlots)) {
      local soldier = curSoldiers[link]
      return {
        soldier = link
        index = getItemIndex(soldier) ?? 0
        squad = getLinkedSquadGuid(soldier)
      }
    }

  return null
}

local availableUpgradesByArmy = ::Computed(function() {
  local itemsCount = itemCountByArmy.value
  local allTemplates = allItemTemplates.value
  local modifyConfig = itemsModifyConfig.value
  local upgradeCostMult = upgradeCostMultByArmy.value

  local res = {}
  foreach(armyId in curArmiesList.value) {
    res[armyId] <- {}
    local armyItemsCount = itemsCount?[armyId] ?? {}
    local armyUpgradeCostMult = upgradeCostMult?[armyId]
    foreach (tpl, count in armyItemsCount) {
      local itemTemplate = allTemplates?[armyId][tpl]
      if ((itemTemplate?.upgradeitem ?? "") == ""
        || (itemTemplate?.disassembly ?? "") == "")
        continue

      local upgradeMult = armyUpgradeCostMult?[tpl] ?? 1.0
      local upgradeReq = (modifyConfig?[itemTemplate?.tier ?? 0].upgradeRequired ?? 0)
      local itemPartsReq = ceil(upgradeReq * upgradeMult).tointeger()
      if (itemPartsReq <= 0)
        continue

      local itemPartsCount = armyItemsCount?[itemTemplate.disassembly] ?? 0
      if (itemPartsCount < itemPartsReq)
        continue

      res[armyId][tpl] <- true
    }
  }
  return res
})

local availableUpgradesEquipsByArmy = ::Computed(function() {
  local armiesItems = itemsByArmies.value
  local armiesSoldiers = soldiersByArmies.value
  local armiesSquads = chosenSquadsByArmy.value
  local upgradesByArmy = availableUpgradesByArmy.value

  local res = {}
  foreach(armyId in curArmiesList.value) {
    local armyRes = {}
    local squadsIndexes = {}
    foreach (idx, squad in armiesSquads?[armyId] ?? [])
      squadsIndexes[squad.guid] <- idx

    local armyUpgrades = upgradesByArmy?[armyId] ?? {}
    local armyItems = armiesItems?[armyId] ?? {}
    local armySoldiers = armiesSoldiers?[armyId] ?? {}
    foreach(item in armyItems) {
      local tpl = item.basetpl
      if (tpl not in armyUpgrades)
        continue

      local equipData = getEquipInfoByItem(item, armySoldiers)
      if (equipData == null)
        continue

      if (tpl not in armyRes)
        armyRes[tpl] <- []

      armyRes[tpl].append(equipData.__update({
        priority = (squadsIndexes?[equipData.squad] ?? 1000) * 1000 + equipData.index
      }))
    }

    res[armyId] <- armyRes.map(function(tplData) {
      local bestPriority
      local bestIdx
      foreach(idx, itemData in tplData)
        if (bestPriority == null || itemData.priority < bestPriority) {
          bestPriority = itemData.priority
          bestIdx = idx
        }
      return tplData[bestIdx]
    })
  }
  return res
})

local unseenAvailableUpgradesByArmy = ::Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  local res = {}
  foreach(armyId in curArmiesList.value) {
    local seenData = seen.value?[armyId] ?? {}
    res[armyId] <- (availableUpgradesEquipsByArmy.value?[armyId] ?? {})
      .filter(@(v, tpl) tpl not in seenData)
  }
  return res
})

local curUnseenAvailableUpgrades = ::Computed(@()
  unseenAvailableUpgradesByArmy.value?[curArmy.value] ?? {})

local curUnseenUpgradesBySoldier = ::Computed(function() {
  local res = {}
  foreach(availUpgrade in curUnseenAvailableUpgrades.value) {
    local { soldier = null } = availUpgrade
    if (soldier != null)
      res[soldier] <- (res?[soldier] ?? 0) + 1
  }
  return res
})

local curUnseenUpgradesBySquad = ::Computed(function() {
  local res = {}
  foreach(availUpgrade in curUnseenAvailableUpgrades.value) {
    local { squad = null } = availUpgrade
    if (squad != null)
      res[squad] <- (res?[squad] ?? 0) + 1
  }
  return res
})

local unseenUpgradesByArmy = ::Computed(function() {
  local res = {}
  foreach(armyId, armyUpgradesData in unseenAvailableUpgradesByArmy.value) {
    res[armyId] <- {}
    foreach(upgradeData in armyUpgradesData) {
      local { soldier = null } = upgradeData
      if (soldier not in res[armyId])
        res[armyId][soldier] <- true
    }
  }
  return res
})

availableUpgradesEquipsByArmy.subscribe(function(v) {
  foreach(armyId, data in v)
    updateSeen(armyId, data)
})

console.register_command(@() settings(@(s) delete s[SEEN_ID]), "meta.resetSeenUpdates")

return {
  markSeenUpdates
  markUnseenUpdates
  curUnseenAvailableUpgrades
  curUnseenUpgradesBySoldier
  curUnseenUpgradesBySquad
  unseenUpgradesByArmy
}
 