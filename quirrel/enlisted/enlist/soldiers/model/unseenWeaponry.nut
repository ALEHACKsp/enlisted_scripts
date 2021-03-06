local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local { curArmiesList, itemsByArmies } = require("enlisted/enlist/meta/profile.nut")
local { chosenSquadsByArmy, armoryByArmy, soldiersBySquad } = require("state.nut")
local { equipSchemesByArmy } = require("all_items_templates.nut")
local { classSlotLocksByArmy } = require("enlisted/enlist/researches/researchesSummary.nut")
local { debounce } = require("utils/timers.nut")

const SEEN_ID = "seen/weaponry"
local SLOTS = ["primary", "side"]
local SLOTS_MAP = SLOTS.map(@(s) [s, true]).totable()

local seen = ::Computed(@() settings.value?[SEEN_ID]) //<armyId> = { <basetpl> = true }

local unseenArmiesWeaponry = ::Watched({})
local unseenSquadsWeaponry = ::Watched({})
local unseenSoldiersWeaponry = ::Watched({})

local notEquippedTiers = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmiesList.value) {
    local itemsList = armoryByArmy.value?[armyId] ?? []
    local byTpl = {} //<basetpl> = <tier>
    local byItemType = {} //<itemtype> = { <basetpl> = <tier> }
    foreach(item in itemsList) {
      if (item.basetpl in byTpl)
        continue
      local { basetpl, itemtype = "", tier = -1 } = item
      byTpl[basetpl] <- tier
      if (itemtype not in byItemType)
        byItemType[itemtype] <- {}
      byItemType[itemtype][basetpl] <- tier
    }
    res[armyId] <- { byTpl, byItemType }
  }
  return res
})

local unseenTiers = ::Computed(@() !onlineSettingUpdated.value ? {}
  : notEquippedTiers.value.map(function(tiers, armyId) {
    local { byTpl, byItemType } = tiers
    local armySeen = seen.value?[armyId]
    byTpl = byTpl.filter(@(_, basetpl) basetpl not in armySeen)
    byItemType = byItemType
      .map(@(tplList)
        tplList.filter(@(_, basetpl) basetpl not in armySeen)
          .reduce(@(res, tier) ::max(res, tier), -1))
    return { byTpl, byItemType }
  }))

local unseenEquipSlotsTiers = ::Computed(@()
  unseenTiers.value.map(function(tiers, armyId) {
    local res = {} //<schemeId> = { <slotId> = <maxUnseenTier> }
    local { byTpl, byItemType } = tiers
    if (byTpl.len() == 0)
      return res

    foreach(schemeId, scheme in equipSchemesByArmy.value?[armyId] ?? {}) {
      local unseenSlots = {}
      foreach(slotId in SLOTS) {
        if (slotId not in scheme)
          continue
        local { itemTypes = [], items = [] } = scheme[slotId]
        local maxTier = -1
        foreach(iType in itemTypes)
          maxTier = ::max(maxTier, byItemType?[iType] ?? -1)
        foreach(tpl in items)
          maxTier = ::max(maxTier, byTpl?[tpl] ?? -1)
        if (maxTier >= 0)
          unseenSlots[slotId] <- maxTier
      }
      if (unseenSlots.len() > 0)
        res[schemeId] <- unseenSlots
    }
    return res
  }))

local slotsLinkTiers = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmiesList.value) {
    res[armyId] <- {}
    foreach(item in itemsByArmies.value?[armyId] ?? {}) {
      if ("tier" not in item)
        continue
      foreach(linkTo, linkSlot in item.links)
        if (linkSlot in SLOTS_MAP) {
          if (linkTo not in res[armyId])
            res[armyId][linkTo] <- {}
          local slotsTiers = res[armyId][linkTo]
          slotsTiers[linkSlot] <- linkSlot in slotsTiers ? ::min(slotsTiers[linkSlot], item.tier) : item.tier
        }
    }
  }
  return res
})

local function recalcUnseen() {
  local unseenArmies = {}
  local unseenSquads = {}
  local unseenSoldiers = {}

  foreach(armyId, schemes in unseenEquipSlotsTiers.value) {
    unseenArmies[armyId] <- 0
    local armyLinkTiers = slotsLinkTiers.value?[armyId]
    local classLocks = classSlotLocksByArmy.value?[armyId]
    foreach(squad in chosenSquadsByArmy.value?[armyId] ?? []) {
      local unseenSoldiersCount = 0
      foreach(soldier in soldiersBySquad.value?[squad.guid] ?? []) {
        local unseenSlots = schemes?[soldier?.equipSchemeId]
        if (unseenSlots == null)
          continue

        local unseenSoldier = {}
        foreach(slotId, tier in unseenSlots)
          if (tier > (armyLinkTiers?[soldier.guid][slotId] ?? -1)
              && !(classLocks?[soldier?.sClass] ?? []).contains(slotId))
            unseenSoldier[slotId] <- true
        if (unseenSoldier.len() == 0)
          continue

        unseenSoldiersCount++
        unseenArmies[armyId]++
        unseenSoldiers[soldier.guid] <- unseenSoldier
      }
      unseenSquads[squad.guid] <- unseenSoldiersCount
    }
  }

  unseenArmiesWeaponry(unseenArmies)
  unseenSquadsWeaponry(unseenSquads)
  unseenSoldiersWeaponry(unseenSoldiers)
}
recalcUnseen()
local recalcUnseenDebounced = debounce(recalcUnseen, 0.01)
unseenEquipSlotsTiers.subscribe(@(_) recalcUnseenDebounced())
chosenSquadsByArmy.subscribe(@(_) recalcUnseenDebounced())
soldiersBySquad.subscribe(@(_) recalcUnseenDebounced())
slotsLinkTiers.subscribe(@(_) recalcUnseenDebounced())
classSlotLocksByArmy.subscribe(@(_) recalcUnseenDebounced())

local function markWeaponrySeen(armyId, basetpl) {
  if (!onlineSettingUpdated.value || (seen.value?[armyId][basetpl] ?? false))
    return

  settings(function(set) {
    local saved = clone (set?[SEEN_ID] ?? {})
    local armySaved = clone (saved?[armyId] ?? {})
    armySaved[basetpl] <- true
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

local function markNotFreeWeaponryUnseen() {
  local seenData = seen.value ?? {}
  if (seenData.len() == 0)
    return false

  local hasChanges = false
  local newSeen = clone seenData
  foreach(armyId, tiers in notEquippedTiers.value) {
    if (armyId not in newSeen)
      continue

    local { byTpl } = tiers
    local armySeen = newSeen[armyId].filter(@(_, tpl) tpl in byTpl)
    if (armySeen.len() < newSeen[armyId].len()) {
      newSeen[armyId] = armySeen
      hasChanges = true
    }
  }

  if (hasChanges)
    settings(@(set) set[SEEN_ID] <- newSeen)
  return hasChanges
}

local needIgnoreSelfUpdateUnseen = false
unseenSoldiersWeaponry.subscribe(function(_) {
  if (!onlineSettingUpdated.value || itemsByArmies.value.len() == 0)
    return
  if (needIgnoreSelfUpdateUnseen)
    needIgnoreSelfUpdateUnseen = false
  else
    needIgnoreSelfUpdateUnseen = markNotFreeWeaponryUnseen()
})

return {
  unseenTiers
  unseenArmiesWeaponry
  unseenSquadsWeaponry
  unseenSoldiersWeaponry

  markWeaponrySeen
  markNotFreeWeaponryUnseen
}
 