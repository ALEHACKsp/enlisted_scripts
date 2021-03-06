local ipc = require("ipc")
local armyData = require("armyData.nut")
local soldiersData = require("soldiersData.nut")
local scoringPlayers = require("enlisted/ui/hud/state/scoring_players.nut")
local sharedWatched = require("globals/sharedWatched.nut")
local { teams } = require("enlisted/ui/hud/state/teams.nut")
local { localPlayerEid, localPlayerTeam } = require("ui/hud/state/local_player.nut")
local { isDebugDebriefingMode } = require("enlisted/globals/wipFeatures.nut")
local { get_session_id } = require("app")


local debriefingData = persist("debriefingData", @() Watched(null))
local debriefingShow = persist("debriefingShow", @() Watched(false))

const INVALID_SESSION = "0"

local singleMissionRewardId = sharedWatched("singleMissionRewardId", @() null)
local singleMissionRewardSum = sharedWatched("singleMissionRewardSum", @() 0)

local debriefingUpdateData = persist("debriefingUpdateData", @() ::Watched({}))
local battleStats = persist("battleStats", @() ::Watched({}))
local isMissionSuccess = ::Computed(@() debriefingData.value?.result.success)
local canApplyRewards = keepref(::Computed(@() battleStats.value.len() > 0
  && (get_session_id() != INVALID_SESSION
    || isDebugDebriefingMode
    || (singleMissionRewardId.value != null && isMissionSuccess.value))))


local mkGetExpToNextLevel = @(expToLevel, expToPerkOnMaxLevel)
  @(level, maxLevel)
    level < (maxLevel ?? (expToLevel.len() - 1))
      ? (expToLevel?[level] ?? expToPerkOnMaxLevel)
      : expToPerkOnMaxLevel

local function extrapolateStatsExp(soldier, expData, getExpToNextLevel) {
  local { maxLevel, level, exp, availPerks } = soldier
  local addExp = expData.exp
  local nextExp = getExpToNextLevel(level, maxLevel)
  local wasExp = {
    exp = exp
    level = level
    availPerks = availPerks
    nextExp = nextExp
  }
  exp += addExp
  while(nextExp > 0 && exp >= nextExp) {
    exp -= nextExp
    if (level < maxLevel)
      level++
    availPerks++
    nextExp = getExpToNextLevel(level, maxLevel)
  }

  return expData.__merge({
    exp = addExp
    wasExp = wasExp
    newExp = {
      exp = exp
      level = level
      availPerks = availPerks
      nextExp = nextExp
    }
  })
}

local chargeExp = @(expData) ipc.send({
  msg = "charge_battle_exp_rewards"
  data = expData
})

local function getSquadData(squadId) {
  local squad = (armyData.value?.squads ?? []).findvalue(@(s) s.squadId == squadId)
  return {
    nameLocId = squad?.nameLocId
    titleLocId = squad?.titleLocId
    icon = squad?.icon
    wasExp = squad?.exp ?? 0
    wasLevel = squad?.level ?? 0
    toLevelExp = squad?.toLevelExp ?? 0
    battleExpBonus = squad?.battleExpBonus ?? 0.0
  }
}

local function shareExp(list, expSum) {
  local oneExp = (expSum / (list.len() || 1)).tointeger()
  return list.map(@(_) { exp = oneExp })
}

local function calcSingleMissionExpReward(expReward) {
  local expSum = (armyData.value?.premiumExpMul ?? 1.0) * singleMissionRewardSum.value
  return {
    armyExp = expSum.tointeger()
    squadsExp = shareExp(expReward?.squadsExp ?? {}, expSum)
    soldiersExp = shareExp(expReward?.soldiersExp ?? {}, expSum)
  }
}

local function applyRewardOnce() {
  if (debriefingUpdateData.value.len())
    return //already applied

  ::log("SoldiersReward: Receive squads stats")
  local armyId = armyData.value?.armyId
  if (armyId == null) {
    ::log("SoldiersReward: Skip soldiers exp reward due unknown armyId")
    return
  }

  local isSingleMission = get_session_id() == INVALID_SESSION
  local sMissionRewardId = isSingleMission ? singleMissionRewardId.value : null
  local { armyExp = 0, squadsExp = {}, soldiersExp = {} }
    = !isSingleMission || isDebugDebriefingMode ? battleStats.value?.expReward
      : sMissionRewardId != null ? calcSingleMissionExpReward(battleStats.value?.expReward)
      : null

  local items = {}
  local stats = {}
  foreach(guid, data in battleStats.value?.stats ?? {}) {
    local soldier = soldiersData.value?[guid]
    if (!soldier) {
      ::log("SoldiersReward: Not found soldier {0} in army {1} for reward. Skip. ".subst(guid, armyId))
      continue
    }
    items[guid] <- soldier
    stats[guid] <- data
  }

  local getExpToNextLevel = mkGetExpToNextLevel(armyData.value?.expToLevel ?? [], armyData.value?.expToPerkOnMaxLevel ?? 0)
  local statsWithExp = stats.map(
    @(s, guid) s.__merge(extrapolateStatsExp(soldiersData.value[guid], soldiersExp?[guid] ?? { exp = 0 }, getExpToNextLevel)))

  debriefingUpdateData({
    armyId = armyId
    singleMissionRewardId = sMissionRewardId
    soldiers = {
      items = items
      stats = statsWithExp
    }
    squads = squadsExp.map(@(expData,  squadId) getSquadData(squadId).__update(expData))
    armyExp = armyExp
    armyWasExp = armyData.value?.exp
    armyWasLevel = armyData.value?.level
    armyProgress = armyData.value?.armyProgress
    premiumExpMul = armyData.value?.premiumExpMul
  })

  if (sMissionRewardId != null && !isDebugDebriefingMode)
    chargeExp({
      armyId = armyId
      singleMissionRewardId = sMissionRewardId
      soldiersExp = soldiersExp.map(@(ed) ed.exp)
      squadsExp = squadsExp.map(@(ed) ed.exp)
      armyExp = armyExp
    })
}

canApplyRewards.subscribe(function(c) { if (c) applyRewardOnce() })

::ecs.register_es("soldiers_stats_listener_es",
  { [::ecs.sqEvents.EventOnSquadStats] = @(evt, eid, comp) battleStats(evt.data ?? {}) }, {})

//we send only base data, because userstats update will be the same in enlist vm
local function subscribeDebriefingWatches(data = debriefingData, show = debriefingShow) {
  data.subscribe(@(val) ipc.send({ msg = "debriefing.data", data = val }))
  show.subscribe(@(val) ipc.send({ msg = "debriefing.show", show = val }))
}

local debriefingDataExt = ::Computed(function(){
  if (debriefingData.value == null)
    return null
  local teamsData = {}
  foreach (team in teams.value)
    if (team?["team.id"])
      teamsData[team["team.id"].tostring()] <- { icon = team?["team.icon"] }
  local res = debriefingData.value
    .__merge({
      localPlayerEid = localPlayerEid.value
      players = scoringPlayers.value
      myTeam = localPlayerTeam.value
      teams = teamsData
      armyId = armyData.value?.armyId
      exitToLobby = true //we no need false in enlisted
    })
    .__update(debriefingUpdateData.value)
  return res
})

debriefingDataExt.subscribe(@(val) debriefingShow(val!=null && val.len()>0))
subscribeDebriefingWatches(debriefingDataExt, debriefingShow)

return {
  debriefingData = debriefingData
  debriefingDataExt = debriefingDataExt
  debriefingShow = debriefingShow
}
 