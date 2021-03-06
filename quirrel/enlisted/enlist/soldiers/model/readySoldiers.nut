local { isEqual } = require("std/underscore.nut")
local { debounce } = require("utils/timers.nut")
local {
  curSquad, curSquadSoldiersInfo, soldiersBySquad, vehicleBySquad, objInfoByGuid,
  curCampSquads, curCampItems, curCampSoldiers
} = require("state.nut")
local { getLinkedArmyName, getLinkedSlotData } = require("enlisted/enlist/meta/metalink.nut")
local squadsParams = require("squadsParams.nut")
local readyStatus = require("readyStatus.nut")
local { READY, OUT_OF_VEHICLE, TOO_MUCH_CLASS, OUT_OF_SQUAD_SIZE, NOT_READY_BY_EQUIP } = readyStatus


local invalidEquipSoldiers = persist("invalidEquipSoldiers" , @() ::Watched(null))

local function updateInvalidSoldiers() {
  local equipped = {}
  foreach(item in curCampItems.value) {
    local sd = getLinkedSlotData(item)
    if (sd == null)
      continue
    local { linkTgt, linkSlot } = sd
    if (linkTgt not in equipped)
      equipped[linkTgt] <- {}
    equipped[linkTgt][linkSlot] <- true
  }

  local invalid = curCampSoldiers.value
    .filter(function(soldier) {
      if (soldier?.hasVerified == false)
        return true
      local { equipScheme = null } = soldier
      if (equipScheme == null)
        return false //mostly happen on login when configs not received yet

      local slotsData = {}
      foreach(slotType, slot in equipScheme) {
        local { atLeastOne = "" } = slot
        if (atLeastOne == "" || slotsData?[atLeastOne] == true)
          continue
        slotsData[atLeastOne] <- equipped?[soldier.guid][slotType] ?? false
      }
      return slotsData.findindex(@(s) s == false) != null
    })
    .map(@(s) true)

  if (!isEqual(invalid, invalidEquipSoldiers.value))
    invalidEquipSoldiers(invalid)
}
if (invalidEquipSoldiers.value == null)
  updateInvalidSoldiers()
local updateInvalidSoldiersDebounced = debounce(updateInvalidSoldiers, 0.01)
curCampItems.subscribe(@(_) updateInvalidSoldiersDebounced())
curCampSoldiers.subscribe(@(_) updateInvalidSoldiersDebounced())

local getSoldiersBattleReady = ::kwarg(
  function(squadSize, maxClasses, soldiers, vehicle, invalidSoldiers) {
    local res = {}
    local vehicleSize = vehicle?.crew ?? squadSize
    local totalReady = 0
    local usedClasses = {}
    foreach(idx, soldier in soldiers) {
      local state = READY
      local sClass = soldier?.sClass
      if (soldier.guid in invalidSoldiers)
        state = state | NOT_READY_BY_EQUIP
      else if (totalReady >= squadSize)
        state = state | OUT_OF_SQUAD_SIZE
      else if ((usedClasses?[sClass] ?? 0) >= (maxClasses?[sClass] ?? 0))
        state = state | TOO_MUCH_CLASS
      else {
        if (totalReady >= vehicleSize)
          state = state | OUT_OF_VEHICLE
        totalReady++
        usedClasses[sClass] <- (usedClasses?[sClass] ?? 0) + 1
      }

      res[soldier.guid] <- state
    }

    return res
  })

local soldiersStatuses = ::Computed(function() {
  local res = {}
  local sqParams = squadsParams.value
  foreach (squad in curCampSquads.value) {
    local armyId = getLinkedArmyName(squad)
    local params = sqParams?[armyId][squad.squadId]
    if (params == null)
      return null

    local vehicleGuid = vehicleBySquad.value?[squad.guid].guid
    res.__update(getSoldiersBattleReady({
      squadSize = params?.size ?? 0
      maxClasses = params?.maxClasses ?? {}
      soldiers = (soldiersBySquad.value?[squad.guid] ?? [])
        .map(@(soldier) objInfoByGuid.value?[soldier.guid] ?? soldier)
      vehicle = vehicleGuid ? objInfoByGuid.value?[vehicleGuid] : null
      invalidSoldiers = invalidEquipSoldiers.value
    }))
  }
  return res
})

local curSquadSoldiersStatus = ::Computed(function() {
  local res = {}
  foreach (soldier in soldiersBySquad.value?[curSquad.value?.guid] ?? [])
    res[soldier.guid] <- soldiersStatuses.value?[soldier.guid] ?? OUT_OF_SQUAD_SIZE
  return res
})

local curSquadSoldiersReady = ::Computed(@() curSquadSoldiersInfo.value.filter(@(soldier)
  curSquadSoldiersStatus.value?[soldier?.guid] == READY))

return {
  soldiersStatuses = soldiersStatuses
  curSquadSoldiersStatus = curSquadSoldiersStatus
  curSquadSoldiersReady = curSquadSoldiersReady
  invalidEquipSoldiers = invalidEquipSoldiers
}.__update(readyStatus)
 