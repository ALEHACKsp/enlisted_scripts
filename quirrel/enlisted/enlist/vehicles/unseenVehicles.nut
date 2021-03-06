local { settings, onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local { curArmiesList } = require("enlisted/enlist/meta/profile.nut")
local { chosenSquadsByArmy, armoryByArmy, vehicleBySquad, itemCountByArmy
} = require("enlisted/enlist/soldiers/model/state.nut")
local allowedVehicles = require("allowedVehicles.nut")
local { debounce } = require("utils/timers.nut")

const SEEN_ID = "seen/vehicles"

local seen = ::Computed(@() settings.value?[SEEN_ID]) //<armyId> = { <basetpl> = true }

local unseenArmiesVehicle = ::Watched({})
local unseenSquadsVehicle = ::Watched({})

local notEquippedTiers = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmiesList.value) {
    local itemsList = armoryByArmy.value?[armyId] ?? []
    local armyTpls = {}
    foreach(item in itemsList)
      if (item?.itemtype == "vehicle")
        armyTpls[item.basetpl] <- item?.tier ?? -1
    res[armyId] <- armyTpls
  }
  return res
})

local unseenTiers = ::Computed(@() !onlineSettingUpdated.value ? {}
  : notEquippedTiers.value.map(function(tiers, armyId) {
    local armySeen = seen.value?[armyId]
    return tiers.filter(@(_, basetpl) basetpl not in armySeen)
  }))

local chosenSquadsTiers = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmiesList.value) {
    local armyVehicles = {}
    foreach(squad in chosenSquadsByArmy.value?[armyId] ?? [])
      if (squad.vehicleType != "")
        armyVehicles[squad.guid] <- {
          tier = vehicleBySquad.value?[squad.guid].tier ?? -1
          squadId = squad.squadId
        }
    res[armyId] <- armyVehicles
  }
  return res
})

local function recalcUnseen() {
  local unseenArmies = {}
  local unseenSquads = {}

  foreach(armyId, tiers in unseenTiers.value) {
    unseenArmies[armyId] <- 0
    foreach(squadGuid, tierData in chosenSquadsTiers.value?[armyId] ?? []) {
      local { squadId, tier } = tierData
      local unseenVehicles = (allowedVehicles.value?[armyId][squadId] ?? {})
        .filter(@(isUsable, vehicleTpl) isUsable && tier < (tiers?[vehicleTpl] ?? -1))

      if (unseenVehicles.len() == 0)
        continue
      unseenSquads[squadGuid] <- unseenVehicles
      unseenArmies[armyId]++
    }
  }

  unseenArmiesVehicle(unseenArmies)
  unseenSquadsVehicle(unseenSquads)
}
recalcUnseen()
local recalcUnseenDebounced = debounce(recalcUnseen, 0.01)
unseenTiers.subscribe(@(_) recalcUnseenDebounced())
chosenSquadsTiers.subscribe(@(_) recalcUnseenDebounced())
allowedVehicles.subscribe(@(_) recalcUnseenDebounced())

local function markVehicleSeen(armyId, basetpl) {
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

local function markNotFreeVehiclesUnseen() {
  local seenData = seen.value ?? {}
  if (seenData.len() == 0)
    return false

  local hasChanges = false
  local newSeen = clone seenData
  foreach(armyId, curArmySeen in seenData) {
    local counts = itemCountByArmy.value?[armyId] ?? {}
    if (counts.len() == 0)
      continue

    local newArmySeen = curArmySeen.filter(@(_, tpl) tpl in counts)
    if (newArmySeen.len() < curArmySeen.len()) {
      newSeen[armyId] = newArmySeen
      hasChanges = true
    }
  }

  if (hasChanges)
    settings(@(set) set[SEEN_ID] <- newSeen)
  return hasChanges
}

itemCountByArmy.subscribe(function(_) {
  if (onlineSettingUpdated.value)
    markNotFreeVehiclesUnseen()
})

return {
  unseenArmiesVehicle
  unseenSquadsVehicle

  markVehicleSeen
}
 