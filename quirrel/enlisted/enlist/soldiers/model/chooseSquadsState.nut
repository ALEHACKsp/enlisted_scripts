local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { soldiersBySquad, unlockedSquadsByArmy, chosenSquadsByArmy, vehicleBySquad, limitsByArmy,
  armyLimitsDefault, changeSquadOrder, curArmy, squadsByArmy
} = require("state.nut")
local { squadsCfgById } = require("enlisted/enlist/soldiers/model/config/squadsConfig.nut")
local { soldiersStatuses } = require("readySoldiers.nut")
local { READY } = require("readyStatus.nut")
local { allSquadsLevels } = require("enlisted/enlist/researches/researchesState.nut")
local { markSeenSquads } = require("unseenSquads.nut")
local msgbox = require("enlist/components/msgbox.nut")

local { curArmySquadsUnlocks, curArmyLevel } = require("armyUnlocksState.nut")


local justGainSquadId = ::Watched(null)
local selectedSquadId = ::Watched(null)
local squadsArmy = persist("squadsArmy", @() ::Watched(null))
local curChoosenSquads = ::Computed(@() chosenSquadsByArmy.value?[squadsArmy.value] ?? [])
local curUnlockedSquads = ::Computed(@() unlockedSquadsByArmy.value?[squadsArmy.value] ?? [])

local chosenSquads = persist("chosen", @() ::Watched([]))
local reserveSquads = persist("reserve", @() ::Watched([]))
local unlockedSquads = ::Computed(@() (clone chosenSquads.value).extend(reserveSquads.value))

local curArmyLockedSquadsData = ::Computed(function() {
  local armyLevel = curArmyLevel.value
  local unlocks = curArmySquadsUnlocks.value ?? []
  return (squadsByArmy.value?[curArmy.value] ?? [])
    .filter(@(s) s.locked == true)
    .map(function(s) {
      local unlock = unlocks.findvalue(@(u) u.unlockId == s.squadId)
      return {
        squad = s
        unlockData = unlock
          ? {
              level = unlock.level
              canUnlock = armyLevel >= unlock.level
            }
          : null
      }
    })
    // TODO: Need to show premium squad too
    .filter(@(s) s.unlockData != null)
    .sort(@(a, b) (a.unlockData?.level ?? 0) <=> (b.unlockData?.level ?? 0))
})

local squadsArmyLimits = ::Computed(@() limitsByArmy.value?[squadsArmy.value] ?? armyLimitsDefault)
local maxSquadsInBattle = ::Computed(@() squadsArmyLimits.value.maxSquadsInBattle)


local prepareSquad = @(squad, cfg, squadsLevel) squad.__merge({
  level = squadsLevel?[squad.squadId] ?? 0
  manageLocId = squad?.manageLocId ?? cfg?.manageLocId
  icon = squad?.icon ?? cfg?.icon
  vehicle = squad?.vehicle
  squadSize = squad?.squadSize ?? soldiersBySquad.value?[squad.guid].len() ?? 0
  battleExpBonus = cfg?.battleExpBonus ?? 0
})

local preparedSquads = ::Computed(function() {
  local visOrdered = clone curChoosenSquads.value
  foreach(squad in curUnlockedSquads.value)
    if (curChoosenSquads.value.indexof(squad) == null)
      visOrdered.append(squad)
  return visOrdered.map(@(squad) prepareSquad(squad, squadsCfgById.value?[squadsArmy.value][squad.squadId], allSquadsLevels.value))
})

local function updateSquadsList() {
  local all = preparedSquads.value
  if (all.len() == 0) {
    chosenSquads(@(v) v.clear())
    reserveSquads(@(v) v. clear())
    return
  }
  local byId = {}
  all.each(@(s) byId[s.squadId] <- s)
  local chosen = chosenSquads.value.map(@(s) byId?[s?.squadId])
  local chosenCount = chosen.filter(@(s) s != null).len()
  local reserve = reserveSquads.value.map(@(s) byId?[s.squadId])
    .filter(@(s) s != null)

  if (chosenCount == 0 && reserve.len() == 0) { //new list, or just opened window
    local amount = curChoosenSquads.value.len()
    chosen = all.slice(0, amount)
    reserve = all.slice(amount)

    local gainSquadId = justGainSquadId.value
    if (gainSquadId != null) {
      local gainSquadIdx = chosen.findindex(@(s) s.squadId == gainSquadId)
      if (gainSquadIdx != null)
        reserve = [chosen.remove(gainSquadIdx)].extend(reserve)
    }
  }
  else {
    local left = clone byId
    chosen.each(function(s) { if (s != null) delete left[s.squadId] })
    reserve.each(@(s) delete left[s.squadId])
    foreach(squad in all)
      if (squad.squadId in left)
        reserve.append(squad)
  }

  if (chosen.len() < maxSquadsInBattle.value)
    chosen.resize(maxSquadsInBattle.value)

  chosenSquads(chosen)
  reserveSquads(reserve)
}
updateSquadsList()
preparedSquads.subscribe(@(_) updateSquadsList())
maxSquadsInBattle.subscribe(@(_) updateSquadsList())

preparedSquads.subscribe(function(uSquads) {
  if (uSquads.findvalue(@(s) s.squadId == selectedSquadId.value) != null)
    return
  selectedSquadId(uSquads?[0].squadId)
})

local function moveIndex(list, idxFrom, idxTo) {
  local res = clone list
  local val = res.remove(idxFrom)
  res.insert(idxTo, val)
  return res
}

local isVehicleSquad = @(squad) squad.vehicleType != ""
local function getCantTakeReason(squad, squadsList, idxTo) {
  local isVehicle = isVehicleSquad(squad)
  local prevSquad = squadsList[idxTo]
  if (prevSquad != null && isVehicleSquad(prevSquad) == isVehicle)
    return null

  local typeKey = isVehicle ? "maxVehicleSquads" : "maxInfantrySquads"
  local maxType = squadsArmyLimits.value[typeKey]
  if (maxType <= 0)
    return { text = ::loc($"msg/{typeKey}IsZero") }

  local curCount = squadsList.reduce(@(res, s) res + (s != null && isVehicleSquad(s) == isVehicle ? 1 : 0), 0)
  if (curCount < maxType)
    return null
  return ::loc($"msg/{typeKey}Full", { maxSquads = maxType })
}

local function changeSquadOrderByUnlockedIdx(idxFrom, idxTo) {
  local watchFrom = idxFrom < maxSquadsInBattle.value ? chosenSquads : reserveSquads
  if (idxFrom >= maxSquadsInBattle.value)
    idxFrom -= maxSquadsInBattle.value
  local squadIdFrom = watchFrom.value?[idxFrom].squadId
  local watchTo = idxTo < maxSquadsInBattle.value ? chosenSquads : reserveSquads
  if (idxTo >= maxSquadsInBattle.value)
    idxTo -= maxSquadsInBattle.value
  if (watchFrom == watchTo) {
    watchFrom(moveIndex(watchFrom.value, idxFrom, idxTo))
    markSeenSquads(squadsArmy.value, [squadIdFrom])
    return
  }
  if (watchFrom == chosenSquads) {
    if (chosenSquads.value[idxFrom] == null)
      return
    reserveSquads(@(list) list.insert(idxTo, chosenSquads.value[idxFrom]))
    chosenSquads(function(list) { list[idxFrom] = null })
    markSeenSquads(squadsArmy.value, [squadIdFrom])
    return
  }

  local cantChangeReason = getCantTakeReason(reserveSquads.value[idxFrom], chosenSquads.value, idxTo)
  if (cantChangeReason == null) {
    local prevSquad = chosenSquads.value[idxTo]
    chosenSquads(@(list) list[idxTo] = reserveSquads.value[idxFrom])
    reserveSquads(function(list) {
      if (prevSquad)
        list[idxFrom] = prevSquad
      else
        list.remove(idxFrom)
    })
    markSeenSquads(squadsArmy.value, [squadIdFrom])
    return
  }

  msgbox.show({
    uid = "change_squad_order"
    text = cantChangeReason
  })
}

local function changeList() {
  local squadId = selectedSquadId.value
  if (squadId == null)
    return

  local idx = chosenSquads.value.findindex(@(s) s?.squadId == squadId)
  if (idx != null) {
    markSeenSquads(squadsArmy.value, [squadId])
    reserveSquads(@(v) v.insert(0, chosenSquads.value[idx]))
    chosenSquads(function(v) { v[idx] = null })
    return
  }

  idx = reserveSquads.value.findindex(@(s) s.squadId == squadId)
  if (idx == null)
    return

  local newIdx = chosenSquads.value.findindex(@(s) s == null)
  if (newIdx == null) {
    msgbox.show({ text = ::loc("msg/battleSquadsFull") })
    return
  }
  local cantChangeReason = getCantTakeReason(reserveSquads.value[idx], chosenSquads.value, newIdx)
  if (cantChangeReason != null) {
    msgbox.show({
      uid = "change_squad_order"
      text = cantChangeReason
    })
    return
  }

  markSeenSquads(squadsArmy.value, [squadId])
  chosenSquads(function(v) { v[newIdx] = reserveSquads.value[idx] })
  reserveSquads(@(v) v.remove(idx))
}

local selectedSquad = ::Computed(@()
  curUnlockedSquads.value.findvalue(@(squad) squad.squadId == selectedSquadId.value))

local selectedSquadSoldiers = ::Computed(function() {
  local squadGuid = selectedSquad.value?.guid
  if (squadGuid == null)
    return null

  local statuses = soldiersStatuses.value
  return (soldiersBySquad.value?[squadGuid] ?? [])
    .filter(@(soldier) statuses?[soldier?.guid] == READY)
})

local selectedSquadVehicle = ::Computed(@()
  vehicleBySquad.value?[selectedSquad.value?.guid].basetpl)

local close = @() squadsArmy(null)

local function applyAndCloseImpl() {
  local guids = unlockedSquads.value.filter(@(s) s != null)
    .map(@(s) s.guid)
  changeSquadOrder(squadsArmy.value, guids)
  setCurSection("SOLDIERS")
  close()
}

local function applyAndClose() {
  local selCount = chosenSquads.value.filter(@(s) s != null).len()
  if (selCount >= curChoosenSquads.value.len())
    applyAndCloseImpl()
  else
    msgbox.show({
      text = ::loc("msg/notFullSquadsAtApply")
      buttons = [
        { text = ::loc("OK"), action = applyAndCloseImpl, isCurrent = true }
        { text = ::loc("Cancel"), isCancel = true }
      ]
    })
}

local function closeAndOpenCampaign() {
  setCurSection("SQUADS")
  close()
}

return {
  openChooseSquadsWnd = function(army, selSquadId, isNew = false) {
    selectedSquadId(selSquadId)
    justGainSquadId(isNew ? selSquadId : null)
    squadsArmy(army)
  }
  closeChooseSquadsWnd = close
  applyAndClose = applyAndClose
  closeAndOpenCampaign = closeAndOpenCampaign
  squadsArmy = squadsArmy
  squadsArmyLimits = squadsArmyLimits
  maxSquadsInBattle = maxSquadsInBattle
  unlockedSquads = unlockedSquads
  curArmyLockedSquadsData = curArmyLockedSquadsData
  chosenSquads = chosenSquads
  reserveSquads = reserveSquads
  changeSquadOrderByUnlockedIdx = changeSquadOrderByUnlockedIdx
  moveIndex = moveIndex
  changeList = changeList

  selectedSquadId = selectedSquadId
  selectedSquadSoldiers = selectedSquadSoldiers
  selectedSquadVehicle = selectedSquadVehicle
} 