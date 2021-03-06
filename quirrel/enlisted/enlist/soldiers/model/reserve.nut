local trainings = require("enlisted/enlist/meta/clientApi.nut").profile.trainings
local squadsParams = require("squadsParams.nut")
local { curArmy, curArmies_list, limitsByArmy, getItemIndex, soldiersBySquad, curChoosenSquads
} = require("state.nut")
local { soldiersByArmies } = require("enlisted/enlist/meta/profile.nut")
local { getLinkedSquadGuid, getLinksByType } = require("enlisted/enlist/meta/metalink.nut")
local { unseenSoldiers } = require("unseenSoldiers.nut")

local allReserveSoldiers = ::Computed(function() {
  local exclude = {}
  foreach (training in trainings.value)
    foreach (linkType in ["sacrifice", "trainee"])
      foreach (sGuid in getLinksByType(training, linkType))
        exclude[sGuid] <- true

  local res = {}
  foreach (armyId in curArmies_list.value)
    res[armyId] <- (soldiersByArmies.value?[armyId] ?? {})
      .filter(@(s) !(exclude?[s.guid] ?? false) && getLinkedSquadGuid(s) == null)
      .values()
      .sort(@(a, b) getItemIndex(a) <=> getItemIndex(b))
  return res
})

local curArmyReserve = ::Computed(@() allReserveSoldiers.value?[curArmy.value] ?? [])

local curArmyReserveCapacity = ::Computed(@() limitsByArmy.value?[curArmy.value].soldiersReserve ?? 0)

local hasCurArmyReserve = ::Computed(@() curArmyReserve.value.len() < curArmyReserveCapacity.value)

local needSoldiersManageBySquad = ::Computed(function() {
  local res = {}
  local curReserve = curArmyReserve.value ?? []
  if (curReserve.len() <= 0)
    return res

  local curUnseen = unseenSoldiers.value
  local armyId = curArmy.value
  foreach (squad in curChoosenSquads.value) {
    local squadParams = squadsParams.value?[armyId][squad?.squadId]
    local squadSoldiers = soldiersBySquad.value?[squad?.guid] ?? []
    if ((squadParams?.size ?? 0) <= squadSoldiers.len())
      continue

    local reqSoldiers = clone (squadParams?.maxClasses ?? {})
    foreach (soldier in squadSoldiers) {
      local sClass = soldier.sClass
      if (sClass in reqSoldiers)
        reqSoldiers[sClass]--
    }
    local soldier = curReserve.findvalue(@(s) (curUnseen?[s.guid] ?? false)
      && (reqSoldiers?[s.sClass] ?? 0) > 0)
    if (soldier != null)
      res[squad.guid] <- true
  }

  return res
})

return {
  allReserveSoldiers = allReserveSoldiers
  curArmyReserve = curArmyReserve
  curArmyReserveCapacity = curArmyReserveCapacity
  hasCurArmyReserve = hasCurArmyReserve
  needSoldiersManageBySquad = needSoldiersManageBySquad
}
 