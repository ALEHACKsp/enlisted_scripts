local { soldiersStatuses, READY } = require("enlisted/enlist/soldiers/model/readySoldiers.nut")
local { chosenSquadsByArmy, soldiersBySquad, curArmies_list, curArmy, playerSelectedArmy, curSquadId
} = require("enlisted/enlist/soldiers/model/state.nut")
local { matchRandomTeam } = require("enlist/quickMatchQueue.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")

local showNotReadySquads = ::Watched(null)
local armiesForBattle = ::Computed(@() matchRandomTeam.value ? curArmies_list.value : [curArmy.value])

local function calcSquadReady(squad, soldiers, statuses) {
  local unreadySoldiers = soldiers.filter(@(s) statuses?[s.guid] != READY)
  local notReadyCount = unreadySoldiers.len()
  local minCount = squad.size
  local canBattle = (soldiers.len() - notReadyCount) >= minCount
  local unreadyMsgs = []
  if (!canBattle)
    unreadyMsgs.append(::loc("notReadySquad/notEnoughSoldiers", { minCount }))
  if (unreadySoldiers.len() > 0)
    unreadyMsgs.append(::loc("notReadySquad/hasNotReadySoldiers", { notReadyCount }))
  return { isReady = unreadyMsgs.len() == 0, canBattle, unreadySoldiers, unreadyMsgs, squad }
}

local function getNotReadySquadsInfo(armiesList, chosenSquads, soldiers, statuses) {
  local res = []
  foreach(armyId in armiesList)
    foreach(squad in chosenSquads?[armyId] ?? []) {
      local readyData = calcSquadReady(squad, soldiers?[squad.guid] ?? [], statuses)
      if (!readyData.isReady)
        res.append(readyData)
    }
  return res
}

local function showCurNotReadySquadsMsg(onContinue) {
  local notReadyInfo = getNotReadySquadsInfo(armiesForBattle.value, chosenSquadsByArmy.value,
    soldiersBySquad.value, soldiersStatuses.value)
  if (notReadyInfo.len() == 0)
    onContinue()
  else
    showNotReadySquads({ notReady = notReadyInfo, onContinue = onContinue })
}

local function goToSquadAndClose(squad) {
  showNotReadySquads(null)
  local armyId = getLinkedArmyName(squad)
  if (curArmies_list.value.indexof(armyId) == null)
    return
  playerSelectedArmy(armyId)
  local { squadId } = squad
  if ((chosenSquadsByArmy.value?[armyId] ?? []).findvalue(@(s) s.squadId == squadId) != null)
    curSquadId(squadId)
}

return {
  getNotReadySquadsInfo = getNotReadySquadsInfo
  showCurNotReadySquadsMsg = showCurNotReadySquadsMsg
  goToSquadAndClose = goToSquadAndClose

  showNotReadySquads = showNotReadySquads
} 