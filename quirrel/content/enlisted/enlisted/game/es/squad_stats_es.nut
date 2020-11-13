local {TEAM_UNASSIGNED} = require("team")
local log = require("std/log.nut")().with_prefix("[BattleReward] ")
local {EventAnyEntityDied} = require("deathevents")
local {EventLevelLoaded} = require("gameevents")
local {EventTeamRoundResult} = require("teamevents")
local { get_team_eid, find_player_by_connid, find_local_player } = require("globals/common_queries.nut")
local isDedicated = require_optional("dedicated") != null
local { has_network, get_sync_time, INVALID_CONNECTION_ID } = require("net")
local profile = require("game/utils/profile.nut")
local { INVALID_USER_ID } = require("matching.errors")
local { isDebugDebriefingMode } = require("enlisted/globals/wipFeatures.nut")
local { updateStatsForExpCalc, calcExpReward } = require_optional("dedicated") == null && !isDebugDebriefingMode
  ? require("enlisted/game/utils/calcExpRewardSingle.nut")
  : require("dedicated/enlisted/calcExpReward.nut")
local sendBqBattleResult = require("enlisted/game/utils/bq_send_Battle_result.nut")

local stats = persist("stats", @() {})
local playersSquads = persist("playersSquads", @() {})
local isResultSend = persist("isResultSend", @() { value = false })
local resultSendToProfile = persist("resultSendToProfile", @() {})
local disconnectInfo = persist("disconnectInfo", @() {})

local teamScoresQuery = ::ecs.SqQuery("teamScoresQuery",
  { comps_ro = [["team.army", ::ecs.TYPE_STRING], ["team.score", ::ecs.TYPE_FLOAT], ["team.scoreCap", ::ecs.TYPE_FLOAT]] })

local newStats = @() {
  spawns = 0
  killed = 0 //suicide does not count
  kills = 0
  tankKills = 0
  planeKills = 0
  assists = 0
  captures = 0
  crewKillAssists = 0
  crewTankKillAssists = 0
  crewPlaneKillAssists = 0
  time = 0.0
  spawnTime = -1
  score = 0
}

local function getMemberData(squadEid, guid) {
  if (!(squadEid in stats))
    stats[squadEid] <- {}
  local squadStats = stats[squadEid]
  if (!(guid in squadStats))
    squadStats[guid] <- newStats()
  return squadStats[guid]
}

local function listSquadPlayer(squadEid) {
  if (squadEid in playersSquads)
    return
  playersSquads[squadEid] <- ::ecs.get_comp_val(squadEid, "squad.ownerPlayer") ?? INVALID_ENTITY_ID
}

local function onMemberCreated(evt, eid, comp) {
  local guid = comp["guid"]
  if (!guid || !guid.len())
    return

  listSquadPlayer(comp["squad_member.squad"])
  local data = getMemberData(comp["squad_member.squad"], guid)
  data.spawns++
  data.spawnTime = get_sync_time()
  log("onMemberCreated ", comp["squad_member.squad"], guid)
}

local function onEntityDied(evt, eid, comp) {
  //evt = [victimEid, offenderEid, offenderSquadEid, victimSquadEid, offenderPlayer, victimPlayer]
  local victimGuid = ::ecs.get_comp_val(evt[0], "guid") ?? ""
  if (victimGuid == "")
    return

  local victimSquadEid = evt[3]
  log("onMemberDied ", victimSquadEid, victimGuid)
  local victimData = getMemberData(victimSquadEid, victimGuid)
  if (victimData.spawnTime > 0) {
    victimData.time += get_sync_time() - victimData.spawnTime
    victimData.spawnTime = -1
  }

  local offenderSquadEid = evt[2]
  local offenderGuid = ::ecs.get_comp_val(evt[1], "guid") ?? ""
  if (offenderSquadEid == victimSquadEid || offenderGuid == "")
    return

  local offenderData = getMemberData(offenderSquadEid, offenderGuid)
  offenderData.kills++
  victimData.killed++
}

local function onSquadMembersStats(evt, _, __) {
  foreach(data in evt.data.list) {
    local { stat, squadEid = INVALID_ENTITY_ID, guid = "", eid = INVALID_ENTITY_ID, amount = 1
    } = data

    if (eid != INVALID_ENTITY_ID) {
      squadEid = ::ecs.get_comp_val(eid, "squad_member.squad") ?? INVALID_ENTITY_ID
      guid = ::ecs.get_comp_val(eid, "guid") ?? ""
    }
    if (squadEid == INVALID_ENTITY_ID || guid == "")
      continue

    local mData = getMemberData(squadEid, guid)
    mData[stat] += amount
  }
}

local function finalizeSingleSpawnStats(dataList) {
  foreach(data in dataList)
    if (data.spawnTime >= 0) {
      data.time += get_sync_time() - data.spawnTime
      data.spawnTime = -1
    }
  return dataList
}

local function mergeStats(to, from) {
  foreach(guid, data in from)
    if (!(guid in to))
      to[guid] <- clone data
    else
      foreach(key, val in data)
        to[guid][key] += val
  return to
}

local function getArmyId(playerEid) {
  local team = ::ecs.get_comp_val(playerEid, "team", TEAM_UNASSIGNED)
  local teamEid = team != TEAM_UNASSIGNED ? get_team_eid(team) : INVALID_ENTITY_ID
  return ::ecs.get_comp_val(teamEid, "team.army", "")
}

local function sendExpToProfileServer(playerEid, expReward) {
  if (!profile.isEnabled())
    return "Skip apply rewards because of profile not enabled"
  local userId = ::ecs.get_comp_val(playerEid, "userid", INVALID_USER_ID)
  if (userId == INVALID_USER_ID)
    return "Invalid userid"
  local armyId = getArmyId(playerEid)
  if (armyId == "")
    return "Missing armyId"

  if (userId in resultSendToProfile)
    return "Result already send"
  resultSendToProfile[userId] <- true

  log($"Send player reward {userId}: armyExp {armyId} = {expReward?.armyExp ?? 0}")
  profile.sendJob("reward_battle", userId, {
    armyId = armyId,
    armyExp = expReward?.armyExp ?? 0,
    squadsExp = expReward?.squadsExp ?? {},
    soldiersExp = expReward?.soldiersExp ?? {},
  })
  return null
}

local function getArmyData(playerEid) {
  local armies = ::ecs.get_comp_val(playerEid, "armies")?.getAll() ?? {}
  return armies?[getArmyId(playerEid)] ?? {}
}

local function sendPlayerStats(playerEid, playerData, curArmiesState) {
  local dataToSend = { stats = playerData }
  local armyId = getArmyId(playerEid)
  local armyData = getArmyData(playerEid)
  local connectedTime = ::ecs.get_comp_val(playerEid, "connectedAtTime", 0.0)
  local expReward = calcExpReward(playerData, armyData, curArmiesState, armyId, connectedTime)
  local userId = ::ecs.get_comp_val(playerEid, "userid", INVALID_USER_ID)
  if (expReward.len() == 0)
    log($"Player {playerEid} has no exp rewards.", playerData)
  else if (!isDedicated)
    dataToSend.expReward <- expReward
  else {
    local expRewardExt = {
      armyExp = expReward.armyExp
      squadsExp = expReward.squadsExp.map(@(s) s.exp)
      soldiersExp = expReward.soldiersExp.map(@(s) s.exp)
    }
    local errText = sendExpToProfileServer(playerEid, expRewardExt)
    if (errText != null)
      log($"Player {playerEid} no rewards error: {errText}")
    else
      dataToSend.expReward <- expReward
    sendBqBattleResult(userId, playerData, expRewardExt, armyData, armyId)
  }

  ::ecs.server_broadcast_net_sqevent(
    ::ecs.event.EventOnSquadStats(dataToSend),
    [::ecs.get_comp_val(playerEid, "connid", INVALID_CONNECTION_ID)])

  if (expReward.len() > 0) {
    log($"Player {userId} reward (army = {armyId}), armiesState = ", curArmiesState,
      "\nexpReward: ", expReward, "\nsoldiersStats: ",
      playerData.map(@(s, guid) s.__merge({ exp = expReward?.soldiersExp[guid] ?? 0 })))
  }
}

local function getCurArmiesState(isFinished) {
  local res = {
    isFinished = isFinished
    time = get_sync_time()
    armies = {}
  }
  teamScoresQuery.perform(function(eid, comp) {
    res.armies[comp["team.army"]] <- { score = comp["team.score"], scoreCap = comp["team.scoreCap"] }
  })
  return res
}

local function onRoundResult(evt, eid, comp) {
  if (isResultSend.value)
    return
  isResultSend.value = true

  local data = {}
  foreach(squadEid, members in stats) {
    local playerEid = playersSquads?[squadEid] ?? INVALID_ENTITY_ID
    if (playerEid != INVALID_ENTITY_ID)
      data[playerEid] <- mergeStats(data?[playerEid] ?? {}, finalizeSingleSpawnStats(members))
  }
  data.each(@(playerSoldiers) playerSoldiers.each(@(v) updateStatsForExpCalc(v)))

  local curArmiesState = getCurArmiesState(true)
  foreach(playerEid, playerData in data)
    sendPlayerStats(playerEid, playerData, disconnectInfo?[playerEid] ?? curArmiesState)
}

local function onGetBattleResult(evt, eid, comp) {
  local net = has_network()
  local senderEid = net ? find_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  if (senderEid != eid)
    return
  local playerData = {}
  foreach(squadEid, members in stats)
    if (playersSquads?[squadEid] == eid)
      mergeStats(playerData, finalizeSingleSpawnStats(members))
  playerData.each(@(data) updateStatsForExpCalc(data))

  local curArmiesState = getCurArmiesState(false)
  disconnectInfo[eid] <- curArmiesState
  sendPlayerStats(eid, playerData, curArmiesState)
}

local function onDisconnectChange(evt, eid, comp) {
  if (!comp.disconnected) {
    if (eid in disconnectInfo)
      delete disconnectInfo[eid]
    return
  }
  disconnectInfo[eid] <- getCurArmiesState(false)
}


::ecs.register_es("squad_stats_es",
  { [::ecs.EventEntityCreated] = onMemberCreated },
  { comps_ro = [
      ["squad_member.squad", ::ecs.TYPE_EID],
      ["guid", ::ecs.TYPE_STRING],
    ]
  }, {tags="server"})

::ecs.register_es("squad_stats_kills_es",
  {
    [EventAnyEntityDied] = onEntityDied,
    [::ecs.sqEvents.EventSquadMembersStats] = onSquadMembersStats,
  },
  {},
  {tags="server"})

::ecs.register_es("send_squad_stats_es",
  { [EventTeamRoundResult] = onRoundResult }, {}, {tags="server"}) //EventTeamRoundResult is a broadcast

::ecs.register_es("get_battle_result_es",
  {
    [::ecs.sqEvents.CmdGetBattleResult] = onGetBattleResult,
    onChange = onDisconnectChange,
  },
  {
    comps_track = [["disconnected", ::ecs.TYPE_BOOL]],
    comps_rq = ["player"],
  },
  {tags="server"})


local function onLevelLoaded(evt, eid, comp) {
  isResultSend.value = false
  stats.clear()
  playersSquads.clear()
  resultSendToProfile.clear()
  disconnectInfo.clear()
}

::ecs.register_es("squad_stats_on_level_load_es", {
  [EventLevelLoaded] = onLevelLoaded
}, {}) 