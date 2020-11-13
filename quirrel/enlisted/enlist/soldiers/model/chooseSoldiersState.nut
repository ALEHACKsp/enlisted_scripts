local { curCampSquads, soldiersBySquad, squadsByArmy, objInfoByGuid
} = require("state.nut")
local {
  manage_squad_soldiers, dismiss_reserve_soldier
} = require("enlisted/enlist/meta/clientApi.nut")
local { allReserveSoldiers } = require("reserve.nut")
local { READY, TOO_MUCH_CLASS, NOT_FIT_CUR_SQUAD, NOT_READY_BY_EQUIP, invalidEquipSoldiers
} = require("readySoldiers.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local squadsParams = require("squadsParams.nut")
local { debounce } = require("utils/timers.nut")
local { collectSoldierData } = require("collectSoldierData.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")
local msgbox = require("enlist/components/msgbox.nut")

local sClassesCfg = require("config/sClassesConfig.nut")

local { curSection} = require("enlisted/enlist/mainMenu/sectionsState.nut")

local selectedSoldierGuid = ::Watched(null)
local soldiersSquadGuid = persist("soldiersSquadGuid", @() ::Watched(null))
local soldiersArmy = ::Computed(function() {
  local squadObj = curCampSquads.value?[soldiersSquadGuid.value]
  return squadObj != null ? getLinkedArmyName(squadObj) : null
})
local soldiersSquad = ::Computed(@() (squadsByArmy.value?[soldiersArmy.value] ?? [])
  .findvalue(@(s) s.guid == soldiersSquadGuid.value))
local curSquadSoldiers = ::Computed(@() soldiersBySquad.value?[soldiersSquadGuid.value] ?? [])
local curReserveSoldiers = ::Computed(@() allReserveSoldiers.value?[soldiersArmy.value] ?? [])

local squadSoldiers = persist("chosen", @() ::Watched([]))
local reserveSoldiers = persist("reserve", @() ::Watched([]))
local soldiersSquadParams = ::Computed(@() squadsParams.value?[soldiersArmy.value][soldiersSquad.value?.squadId])
local maxSoldiersInBattle = ::Computed(@() soldiersSquadParams.value?.size ?? 1)

local selectedSoldier = ::Computed(function() {
  local guid = selectedSoldierGuid.value
  return squadSoldiers.value.findvalue(@(s) s?.guid == guid)
    ?? reserveSoldiers.value.findvalue(@(s) s?.guid == guid)
})

local function calcSoldiersStatuses(squadParams, chosen, reserve, invalidEquip) {
  local maxClasses = squadParams?.maxClasses ?? {}
  local leftClasses = clone maxClasses

  local res = {}
  foreach(soldier in chosen) {
    if (soldier == null)
      continue
    local { sClass } = soldier
    local status = NOT_FIT_CUR_SQUAD | TOO_MUCH_CLASS
    if ((leftClasses?[sClass] ?? 0) > 0) {
      leftClasses[sClass]--
      status = READY
    }
    else if ((maxClasses?[sClass] ?? 0) > 0)
      status = TOO_MUCH_CLASS

    if (invalidEquip?[soldier.guid])
      status = status | NOT_READY_BY_EQUIP

    res[soldier.guid] <- status
  }
  foreach(soldier in reserve) {
    local { sClass } = soldier
    local status = (maxClasses?[sClass] ?? 0) <= 0 ? NOT_FIT_CUR_SQUAD | TOO_MUCH_CLASS
      : (leftClasses?[sClass] ?? 0) <= 0 ? TOO_MUCH_CLASS
      : READY
    if (invalidEquip?[soldier.guid])
      status = status | NOT_READY_BY_EQUIP
    res[soldier.guid] <- status
  }
  return res
}

local soldiersStatuses = ::Computed(@() calcSoldiersStatuses(soldiersSquadParams.value,
  squadSoldiers.value, reserveSoldiers.value, invalidEquipSoldiers.value))

local function updateSoldiersList() {
  local all = (clone curSquadSoldiers.value).extend(curReserveSoldiers.value)
  if (all.len() == 0) {
    squadSoldiers(@(v) v.clear())
    reserveSoldiers(@(v) v. clear())
    return
  }
  local byGuid = {}
  all.each(@(s) byGuid[s.guid] <- s)
  local chosen = squadSoldiers.value.map(@(s) byGuid?[s?.guid])
  local chosenCount = chosen.filter(@(s) s != null).len()
  local reserve = reserveSoldiers.value.map(@(s) byGuid?[s.guid])
    .filter(@(s) s != null)

  local needSort = false
  if (chosenCount == 0 && reserve.len() == 0) { //new list, or just opened window
    chosen = clone curSquadSoldiers.value
    reserve = clone curReserveSoldiers.value
    needSort = true
  }
  else {
    local left = clone byGuid
    chosen.each(function(s) { if (s != null) delete left[s.guid] })
    reserve.each(@(s) delete left[s.guid])
    foreach(soldier in all)
      if (soldier.guid in left)
        reserve.append(soldier)
  }

  local count = maxSoldiersInBattle.value
  if (chosen.len() < count)
    chosen.resize(count)
  else if (chosen.len() > count) {
    reserve = chosen.slice(count).extend(reserve)
    chosen = chosen.slice(0, count)
  }

  local objInfo = objInfoByGuid.value
  local mkSoldierData = @(s) s == null ? s : (collectSoldierData(objInfo?[s.guid] ?? s))
  chosen = chosen.map(mkSoldierData)
  reserve = reserve.map(mkSoldierData)

  if (needSort) {
    local statuses = calcSoldiersStatuses(soldiersSquadParams.value, chosen, reserve, invalidEquipSoldiers.value)
    reserve.sort(@(a, b) statuses[a.guid] <=> statuses[b.guid]
      || b.tier <=> a.tier
      || b.level <=> a.level
      || a.sClass <=> b.sClass)
  }

  squadSoldiers(chosen)
  reserveSoldiers(reserve)
}
updateSoldiersList()
local updateSoldiersListDebounced = debounce(updateSoldiersList, 0.01)
curSquadSoldiers.subscribe(@(_) updateSoldiersListDebounced())
curReserveSoldiers.subscribe(@(_) updateSoldiersListDebounced())
maxSoldiersInBattle.subscribe(@(_) updateSoldiersListDebounced())
objInfoByGuid.subscribe(@(_) updateSoldiersListDebounced())

local function moveIndex(list, idxFrom, idxTo) {
  local res = clone list
  local val = res.remove(idxFrom)
  res.insert(idxTo, val)
  return res
}

local getSClassName = @(sClass) ::loc(soldierClasses?[sClass].locId ?? "unknown")

local function getCantTakeReason(soldier, soldiersList, idxTo) {
  local { sClass } = soldier
  local maxClass = soldiersSquadParams.value?.maxClasses[sClass] ?? 0
  if (maxClass <= 0)
    return ::loc("msg/maxClassInSquadIsZero", { sClass = getSClassName(sClass) })

  local tgtClass = soldiersList?[idxTo].sClass
  if (sClass == tgtClass)
    return null

  local count = soldiersList.filter(@(s) s?.sClass == sClass).len()
  return count < maxClass ? null
    : ::loc("msg/maxClassInSquadIsFull", { sClass = getSClassName(sClass), count = maxClass })
}

local function getCanTakeSlots(soldier, soldiersList) {
  local { sClass } = soldier
  local maxClass = soldiersSquadParams.value?.maxClasses[sClass] ?? 0
  if (maxClass <= 0)
    return array(soldiersList.len(), false)

  local classCount = soldiersList.filter(@(s) s?.sClass == sClass).len()
  if (classCount != maxClass)
    return array(soldiersList.len(), classCount < maxClass)
  return soldiersList.map(@(s) s?.sClass == sClass)
}

local function changeSoldierOrderByIdx(idxFrom, idxTo) {
  local watchFrom = idxFrom < maxSoldiersInBattle.value ? squadSoldiers : reserveSoldiers
  if (idxFrom >= maxSoldiersInBattle.value)
    idxFrom -= maxSoldiersInBattle.value
  local watchTo = idxTo < maxSoldiersInBattle.value ? squadSoldiers : reserveSoldiers
  if (idxTo >= maxSoldiersInBattle.value)
    idxTo -= maxSoldiersInBattle.value
  if (watchFrom == watchTo) {
    watchFrom(moveIndex(watchFrom.value, idxFrom, idxTo))
    return
  }

  if (watchFrom == squadSoldiers) {
    local squadSoldier = squadSoldiers.value[idxFrom]
    if (squadSoldier == null)
      return

    local squadSoldierClass = squadSoldier.sClass
    if (sClassesCfg.value?[squadSoldierClass].isTransferLocked ?? true)
      return msgbox.show({
        text = ::loc("msg/cantMoveClassSoldier", { sClass = getSClassName(squadSoldierClass) })
      })

    reserveSoldiers(@(list) list.insert(idxTo, squadSoldiers.value[idxFrom]))
    squadSoldiers(function(list) { list[idxFrom] = null })
    return
  }

  local cantChangeReason = getCantTakeReason(reserveSoldiers.value[idxFrom], squadSoldiers.value, idxTo)
  if (cantChangeReason == null) {
    local prevSoldier = squadSoldiers.value[idxTo]
    squadSoldiers(@(list) list[idxTo] = reserveSoldiers.value[idxFrom])
    reserveSoldiers(function(list) {
      if (prevSoldier)
        list[idxFrom] = prevSoldier
      else
        list.remove(idxFrom)
    })
    return
  }

  msgbox.show({
    uid = "change_soldiers_order"
    text = cantChangeReason
  })
}

local function moveCurSoldier(direction) {
  local guid = selectedSoldierGuid.value
  if (guid == null)
    return
  foreach(watch in [squadSoldiers, reserveSoldiers]) {
    local list = watch.value
    local idx = list.findindex(@(s) s?.guid == guid)
    if (idx == null)
      continue
    local newIdx = idx + direction
    if (newIdx in list)
      watch(moveIndex(list, idx, newIdx))
    break
  }
}

local function soldierToReserveByIdx(idx) {
  if (idx == null)
    return

  reserveSoldiers(@(v) v.insert(0, squadSoldiers.value[idx]))
  squadSoldiers(function(v) { v[idx] = null })
}

local function curSoldierToReserve() {
  local guid = selectedSoldierGuid.value
  if (guid == null)
    return

  local idx = squadSoldiers.value.findindex(@(s) s?.guid == guid)
  soldierToReserveByIdx(idx)
}

local function soldierToSquadByIdx(idx) {
  if (idx == null)
    return

  local newIdx = squadSoldiers.value.findindex(@(s) s == null)
  if (newIdx == null) {
    msgbox.show({ text = ::loc("msg/squadSoldiersFull") })
    return
  }

  local cantChangeReason = getCantTakeReason(reserveSoldiers.value[idx], squadSoldiers.value, newIdx)
  if (cantChangeReason != null) {
    msgbox.show({
      uid = "change_soldiers_order"
      text = cantChangeReason
    })
    return
  }

  squadSoldiers(function(v) { v[newIdx] = reserveSoldiers.value[idx] })
  reserveSoldiers(@(v) v.remove(idx))
}

local function curSoldierToSquad() {
  local guid = selectedSoldierGuid.value
  if (guid == null)
    return

  local idx = reserveSoldiers.value.findindex(@(s) s.guid == guid)
  soldierToSquadByIdx(idx)
}

local close = @() soldiersSquadGuid(null)

local function applyAndCloseImpl() {
  local minCount = soldiersSquad.value?.size ?? 1
  squadSoldiers(squadSoldiers.value.filter(@(s) s != null))
  for(local i = squadSoldiers.value.len() - 1; i >= 0; i--) {
    local soldier = squadSoldiers.value[i]
    if (soldiersStatuses.value?[soldier.guid] == READY)
      continue
    squadSoldiers(@(v) v.remove(i))
    reserveSoldiers(@(v) v.insert(0, soldier))
  }
  for(local i = squadSoldiers.value.len(); i < minCount; i++) {
    local idx = reserveSoldiers.value.findindex(@(s) soldiersStatuses.value?[s.guid] == READY)
    if (idx == null)
      break
    local soldier = reserveSoldiers.value[idx]
    reserveSoldiers(@(v) v.remove(idx))
    squadSoldiers(@(v) v.append(soldier))
  }
  manage_squad_soldiers(soldiersArmy.value,
    soldiersSquadGuid.value,
    squadSoldiers.value.map(@(s) s.guid),
    reserveSoldiers.value.map(@(s) s.guid))
  close()
}

local function applyAndClose() {
  local selCount = squadSoldiers.value.filter(@(s) s != null).len()
  local readyCount = squadSoldiers.value
    .filter(@(s) s != null && soldiersStatuses.value?[s.guid] == READY)
    .len()
  local hasReady = reserveSoldiers.value.findvalue(@(s) soldiersStatuses.value?[s.guid] == READY) != null
  local minCount = soldiersSquad.value?.size ?? 1
  local msg = readyCount < minCount && hasReady ? ::loc("msg/notFullSoldiersAtApply", { minCount = minCount })
    : readyCount < selCount ? ::loc("msg/haveUnreadySoldiers", { count = selCount - readyCount })
    : null
  if (msg == null)
    applyAndCloseImpl()
  else
    msgbox.show({
      text = msg
      buttons = [
        { text = ::loc("OK"), action = applyAndCloseImpl, isCurrent = true }
        { text = ::loc("Cancel"), isCancel = true }
      ]
    })
}

local isDismissInProgress = ::Watched(false)
local function dismissSoldier(armyId, soldierGuid) {
  if (isDismissInProgress.value)
    return

  isDismissInProgress(true)
  dismiss_reserve_soldier(armyId, soldierGuid, function(res) {
    isDismissInProgress(false)
  })
}

curSection.subscribe(function(v) {
  if (v == "RESEARCHES")
    applyAndClose()
})

return {
  openChooseSoldiersWnd = function(squadGuid, selSoldierGuid = null) {
    soldiersSquadGuid(squadGuid)
    selectedSoldierGuid(selSoldierGuid)
  }
  closeChooseSoldiersWnd = close
  applyAndClose = applyAndClose

  soldiersArmy = soldiersArmy
  soldiersSquadGuid = soldiersSquadGuid
  soldiersSquad = soldiersSquad
  maxSoldiersInBattle = maxSoldiersInBattle
  soldiersSquadParams = soldiersSquadParams
  squadSoldiers = squadSoldiers
  reserveSoldiers = reserveSoldiers
  soldiersStatuses = soldiersStatuses
  selectedSoldierGuid = selectedSoldierGuid
  selectedSoldier = selectedSoldier

  changeSoldierOrderByIdx = changeSoldierOrderByIdx
  moveIndex = moveIndex
  moveCurSoldier = moveCurSoldier
  soldierToReserveByIdx = soldierToReserveByIdx
  curSoldierToReserve = curSoldierToReserve
  soldierToSquadByIdx = soldierToSquadByIdx
  curSoldierToSquad = curSoldierToSquad
  getCanTakeSlots = getCanTakeSlots
  dismissSoldier = dismissSoldier
  isDismissInProgress = isDismissInProgress
}
 