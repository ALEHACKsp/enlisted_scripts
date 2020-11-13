local {TEAM_UNASSIGNED} = require("team")
local debug = require("std/log.nut")().with_prefix("[SPAWN]")
local {logerr} = require("dagor.debug")
local {CmdPossessEntity, CmdSpawnSquad} = require("respawnevents")
local {get_sync_time} = require("net")
local {get_team_eid} = require("globals/common_queries.nut")
local {spawnVehicleSquad, spawnSquad, calcBotCountInVehicleSquad} = require("enlisted/game/utils/squad_spawn.nut")
local {mkSpawnParamsByTeamEx} = require("game/utils/spawn.nut")
local {CmdHeroLogEvent} = require("gameevents")
local {find_respawn_base_for_team_with_type, get_random_respawn_base, get_can_use_respawnbase_type,
       find_all_respawn_bases_for_team_with_type, is_vehicle_spawn_allowed_by_limit} = require("game/utils/respawn_base.nut")
local getPrioritySpawnGroup = require("respawn_priority_auto_selector.nut")

local teamSquadQuery = ::ecs.SqQuery("teamSquadQuery", {
  comps_rw=[
    ["team.score",::ecs.TYPE_FLOAT],
    ["team.squadsCanSpawn", ::ecs.TYPE_BOOL],
  ],
  comps_ro=[
    ["team.id",::ecs.TYPE_INT],
    ["team.squadSpawnCost", ::ecs.TYPE_INT],
    ["team.members", ::ecs.TYPE_ARRAY],
    ["team.firstSpawnCostMul", ::ecs.TYPE_FLOAT],
    ["team.eachSquadMaxSpawns", ::ecs.TYPE_INT],
  ]
})

local teamSquadQueryPerform = @(team, cb) teamSquadQuery.perform(cb, "eq(team.id,{0})".subst(team))

local canSpawnPlayerSquads = @(team, isFirstSpawn, playerSpawnCount)
  teamSquadQueryPerform(team, @(eid, comp) isFirstSpawn || playerSpawnCount != comp["team.eachSquadMaxSpawns"] - 1)

local canSpawnTeamSquads = @(team, playerSpawnCount)
  teamSquadQueryPerform(team, @(eid, comp) comp["team.squadsCanSpawn"] && (comp["team.eachSquadMaxSpawns"] < 0 || playerSpawnCount < comp["team.eachSquadMaxSpawns"]))

local updateTeamScore = @(team, playerSpawnCount) teamSquadQueryPerform(team, function (eid, comp) {
  local membersCount = comp["team.members"].len().tofloat()
  if (membersCount <= 0)
    return
  local spawnCost = comp["team.squadSpawnCost"] / membersCount
  if (playerSpawnCount == 0)
    spawnCost *= comp["team.firstSpawnCostMul"]

  if (spawnCost > 0)
    comp["team.score"] = max(0, comp["team.score"] - spawnCost)
})

local createRespawner = @(team, playerEid, isFirstSpawn=true) ::ecs.g_entity_mgr.createEntity("respawner", {
  ["respawner.player"] = ::ecs.EntityId(playerEid),
  ["respawner.respToBot"] = false,
  ["respawner.isFirstSpawn"] = isFirstSpawn,
  ["respawner.respEndTime"] = 300 + get_sync_time(),
  ["respawner.canRespawnTime"] = 10 + get_sync_time(),
  team = team
  customSpawn = true
},
@(respawnerEid) ::ecs.g_entity_mgr.sendEvent(playerEid, CmdPossessEntity(respawnerEid)))

local function rejectSpawn(reason, team, playerEid) {
  debug($"RejectSpawn: '{reason}' for team {team} and player {playerEid}")
  ::ecs.server_send_event(playerEid, ::ecs.event.EventOnSpawnError({reason=reason}), [::ecs.get_comp_val(playerEid, "connid", -1)])
  createRespawner(team, playerEid, false)
}

local function onSuccessfulSpawn(comp) {
  comp["squads.spawnCount"]++
  if (comp["scoring_player.firstSpawnTime"] <= 0.0)
    comp["scoring_player.firstSpawnTime"] = get_sync_time()
}

local groupSpawnCb = @(team, canUseRespawnbaseType, respawnGroupId)
  get_random_respawn_base(
    find_all_respawn_bases_for_team_with_type(team, canUseRespawnbaseType)
      .filter(@(v) ::ecs.get_comp_val(v[0], "respawnBaseGroup", -1) == respawnGroupId)
  )

local function spawnGroupError(template, team, eid) {
  logerr($"'canUseRespawnbaseType' component is not set for {template}")
  rejectSpawn($"No respawn base for {template} by type", team, eid)
  return false
}

local function avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType) {
  local getRespawnbaseForTeamCb = @(team, safest = false) find_respawn_base_for_team_with_type(team, canUseRespawnbaseType)
  local respawnGroupId = ctx.respawnGroupId
  if (respawnGroupId >= 0)
    getRespawnbaseForTeamCb = @(team, safest = false) groupSpawnCb(team, canUseRespawnbaseType, respawnGroupId)
  return [getRespawnbaseForTeamCb(ctx.team), @(team, possesed) mkSpawnParamsByTeamEx(team, possesed, getRespawnbaseForTeamCb)]
}

local debugAllRespawnbasesQuery = ::ecs.SqQuery("debugAllRespawnbasesQuery", {
  comps_ro=["active", "transform", "team", "lastSpawnOnTime", "respawnbaseType", ["respTime", ::ecs.TYPE_INT, 0], ["maxVehicleOnSpawn", ::ecs.TYPE_INT, -1]]
  comps_rq=["respbase"]
})

local function debugDumpRespawnbases(ctx, canUseRespawnbaseType) {
  debugTableData(ctx)
  debug($"canUseRespawnbaseType = {canUseRespawnbaseType}")

  debugAllRespawnbasesQuery(function(eid, comp) {
    debug($"eid = {eid}")
    debugTableData(comp)
  })
}

local function trySpawnSquad(ctx) {
  local eid                      = ctx.eid;
  local team                     = ctx.team;
  local squadId                  = ctx.squadId;
  local memberId                 = ctx.memberId;
  local botCount                 = ctx.botCount;
  local squadParams              = ctx.squadParams;
  local shouldValidateSpawnRules = ctx.shouldValidateSpawnRules;

  local templateName = squadParams.squad[memberId].gametemplate
  local canUseRespawnbaseType = get_can_use_respawnbase_type(templateName)
  if (canUseRespawnbaseType == null)
    return spawnGroupError(templateName, team, eid)

  if (ctx.respawnGroupId < 0)
    ctx.respawnGroupId = getPrioritySpawnGroup(canUseRespawnbaseType, team)

  local [baseEid, cb] = avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType)
  squadParams.mkSpawnParamsCb <- cb
  if (baseEid == INVALID_ENTITY_ID) {
    if (ctx.respawnGroupId < 0)
      logerr($"Spawn squad [{squadId}, {memberId}] for team {team} is not possible. See log for more details.")
    else {
      debug($"Spawn squad [{squadId}, {memberId}] for team {team} for chosen group {ctx.respawnGroupId} is not possible.")
      ::ecs.g_entity_mgr.sendEvent(eid, CmdHeroLogEvent("group_is_no_longer_active", "respawn/group_is_no_longer_active", 0))
    }
    rejectSpawn("No respawn base for squad", team, eid)
    debugDumpRespawnbases(ctx, canUseRespawnbaseType)
    return false
  }

  debug($"Spawn squad [{squadId}, {memberId}] for team {team} with bot's count {botCount}")

  if (!spawnSquad(squadParams)) {
    if (shouldValidateSpawnRules) {
      rejectSpawn("The squad cannot be created by unknown reason", team, eid)
    }
    return false
  }

  return true
}

local teamPendingQuery = ::ecs.SqQuery("teamPendingQuery", {
  comps_rw = [["team.spawnPending", ::ecs.TYPE_OBJECT]]
})

local function onPlayerAwaitingVehicleSpawn(team, playerEid, respawnbaseType) {
  if (playerEid == INVALID_ENTITY_ID)
    return
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  teamPendingQuery(teamEid, function(eid, comp) {
    local pending = comp["team.spawnPending"]
    pending[respawnbaseType] <- (pending?[respawnbaseType] ?? []).append(::ecs.EntityId(playerEid))
  })
}

local function onPendingVehicleSpawned(squadEid, respawnbaseType) {
  local playerEid = ::ecs.get_comp_val(squadEid, "squad.ownerPlayer") ?? INVALID_ENTITY_ID
  if (playerEid == INVALID_ENTITY_ID)
    return
  local team = ::ecs.get_comp_val(playerEid, "team") ?? TEAM_UNASSIGNED
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  teamPendingQuery(teamEid, function(eid, comp) {
    local pending = comp["team.spawnPending"]
    local index = pending?[respawnbaseType]?.indexof(playerEid, ::ecs.TYPE_EID)
    if (index != null) {
      pending[respawnbaseType].remove(index)
    } else {
      logerr($"Player {playerEid} was not removed from pending list:")
      debugTableData(pending.getAll())
    }
  })
}

local function trySpawnVehicleSquad(ctx) {
  local eid                      = ctx.eid;
  local team                     = ctx.team;
  local squadId                  = ctx.squadId;
  local memberId                 = ctx.memberId;
  local botCount                 = ctx.botCount;
  local vehicle                  = ctx.vehicle;
  local squadParams              = ctx.squadParams;
  local shouldValidateSpawnRules = ctx.shouldValidateSpawnRules;
  local vehicleRespawnsBySquad   = ctx.vehicleRespawnsBySquad;

  local canUseRespawnbaseType = get_can_use_respawnbase_type(vehicle)
  if (canUseRespawnbaseType == null)
    return spawnGroupError(vehicle, team, eid)

  if (ctx.respawnGroupId < 0)
    ctx.respawnGroupId = getPrioritySpawnGroup(canUseRespawnbaseType, team)

  local [baseEid, cb] = avalibleBaseAndSpawnParamsCb(ctx, canUseRespawnbaseType)
  ctx.canUseRespawnbaseType <- canUseRespawnbaseType
  squadParams.mkSpawnParamsCb <- cb
  local nextSpawnOnVehicleInTime = vehicleRespawnsBySquad[squadId].nextSpawnOnVehicleInTime
  if (baseEid == INVALID_ENTITY_ID) {
    debug($"Spawn {vehicle} on base {baseEid} squad [{squadId}, {memberId}] for team {team} is not possible")
    rejectSpawn("No respawn base for vehicle", team, eid)
    debugDumpRespawnbases(ctx, canUseRespawnbaseType)
    return false
  }
  if (shouldValidateSpawnRules && (!is_vehicle_spawn_allowed_by_limit(team, canUseRespawnbaseType) || nextSpawnOnVehicleInTime > get_sync_time())) {
    // In theory this situation is migh be an error (bug), but in practice no one is going to fix it anytime soon
    // (and its' kind hard to due to eventual consistency of replication) so report it as ordinary log message
    debug($"Spawn {vehicle} squad [{squadId}, {memberId}] for team {team} is forbidden by limit")
    rejectSpawn("The vehicle is not ready for this squad", team, eid)
    local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
    debugTableData(::ecs.get_comp_val(teamEid, "team.spawnPending")?.getAll() ?? {})
    return false
  }

  debug($"Spawn vehicle squad [{squadId}, {memberId}] for team {team} with bot's count {botCount}")

  if (!spawnVehicleSquad(squadParams)) {
    if (shouldValidateSpawnRules) {
      rejectSpawn("The squad cannot be created by unknown reason", team, eid)
    }
    return false
  }
  onPlayerAwaitingVehicleSpawn(team, squadParams.playerEid, canUseRespawnbaseType)

  return true
}

local respawnPointsQuery = ::ecs.SqQuery("respawnPointsQuery", {
  comps_ro=[["squads.revivePointsList", ::ecs.TYPE_ARRAY], ["soldier_revive_points.points", ::ecs.TYPE_ARRAY, []]]
})

local function validateRotationComps(squadRevivePoints, soldierRevivePoints, squadId, memberId) {
  if (squadId < 0 || squadId >= squadRevivePoints.len()) {
    logerr($"Squad {squadId} not found in squads.revivePointsList")
    debugTableData(squadRevivePoints)
  } else if (soldierRevivePoints.len() > 0 && (squadId >= soldierRevivePoints.len() || memberId >= soldierRevivePoints[squadId].len())) {
    logerr($"Member {memberId} of squad {squadId} not found in soldier_revive_points.points")
    debugTableData(soldierRevivePoints)
  } else
    return true
  return false
}

local validateSpawnRotation = @(playerEid, squadId, memberId) respawnPointsQuery.perform(playerEid, function(_, comp) {
  if (!validateRotationComps(comp["squads.revivePointsList"], comp["soldier_revive_points.points"], squadId, memberId))
    return false
  local squadRevivePoints = comp["squads.revivePointsList"][squadId]
  local soldierRevivePoints = comp["soldier_revive_points.points"]?[squadId]?[memberId] ?? 100
  return squadRevivePoints == 100 && soldierRevivePoints == 100
}) ?? true

local noBotsModeQuery = ::ecs.SqQuery("noBotsModeQuery", {comps_rq=["noBotsMode"]})

local isNoBotsMode = @() noBotsModeQuery.perform(@(...) true) ?? false

local function onSpawnSquad(evt, eid, comp) {
  local team = evt[0]
  local possessed = evt[1]
  local squadId = evt[2]
  local memberId = evt[3]
  local respawnGroupId = evt[4]
  if (team == TEAM_UNASSIGNED) {
    debug($"Cannot create player possessed entity for team {team}")
    return
  }

  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  debug($"Spaw team {team} squad")

  if (teamEid == INVALID_ENTITY_ID) {
    logerr($"Cannot create player possessed entity for team {team} because of teamEid is invalid")
    return
  }

  local squadParams = {
    squadId   = squadId
    memberId  = memberId
    team      = team
    possessed = possessed
  }

  if (comp.armiesReceivedTime < 0.0 || (comp.armiesReceivedTime > 0 && comp.armiesReceivedTeam != team)) {
    debug($"Armies is not received yet for player {eid}, team {team}")
    comp.delayedSpawnSquad.append(squadParams)
    return
  }

  local playerSpawnCount = comp["squads.spawnCount"]
  comp["squads.squadsCanSpawn"] = canSpawnPlayerSquads(team, comp.isFirstSpawn, playerSpawnCount)

  updateTeamScore(team, playerSpawnCount)

  if (!canSpawnTeamSquads(team, playerSpawnCount)) {
    debug($"Squad spawn is disabled by mission for team {team}")
    return
  }

  if (comp.isFirstSpawn) {
    debug($"The first spawn. Create respawner.")
    comp.isFirstSpawn = false
    createRespawner(team, eid)
    return
  }

  local teamArmy     = ::ecs.get_comp_val(teamEid, "team.army")
  local squadInfo = comp.armies[teamArmy].squads?[squadId]
  if (squadInfo == null) {
    debug($"Squad {squadId} not found. Fallback to 0 squad.")
    squadId = 0
    squadParams.squadId = 0
    squadInfo = comp.armies[teamArmy].squads[0]
  }
  local vehicle = squadInfo?.curVehicle.gametemplate
  local vehicleComps = squadInfo?.curVehicle?.comps?.getAll() ?? {}
  local squad = squadInfo?.squad.getAll() ?? []

  local squadMaxLen = squad.len()
  local botCount = isNoBotsMode() ? 0 : max(0, squadMaxLen - 1)

  // A vehicle squad is allowed to have bots even in mode without bots
  if (vehicle != null)
    botCount = calcBotCountInVehicleSquad(vehicle, squadMaxLen)

  comp["squads.botCount"] = botCount

  // Create deepcopy of native component ecs::Array
  // And slice to requested count: botCount + leader
  if (botCount == 0 && squad?[memberId] != null) {
    // Special game mode without bots. The player sees a whole squad and seletcs a squad member and spawns on it
    squad = [squad[memberId]]
    memberId = 0
    squadParams.memberId = 0
  }
  else
    squad = squad.slice(0, botCount + 1)

  local member = squad?[memberId]
  if (member == null) {
    debug($"Squad member {memberId} not found. Fallback to 0 squad member.")
    memberId = 0
    squadParams.memberId = memberId
  }

  squadParams.__update({
    playerEid = eid
    squad     = squad
    vehicle   = vehicle
    vehicleComps = vehicleComps
  })

  if (comp.isDefaultArmies)
    debug($"Spawn squad {squadId} from default armies")

  local spawnCtx = {
    eid                      = eid
    team                     = team
    squadId                  = squadId
    memberId                 = memberId
    botCount                 = botCount
    squadParams              = squadParams
    shouldValidateSpawnRules = comp.shouldValidateSpawnRules
    respawnGroupId           = respawnGroupId
  }

  local soldierId = squad?[memberId]?.id ?? -1
  if (comp.shouldValidateSpawnRules && !validateSpawnRotation(eid, squadId, soldierId)) {
    rejectSpawn($"Spawn squad {squadId} member {soldierId} is not allowed by spawn rotation rules", team, eid)
    return
  }

  if (vehicle) {
    spawnCtx.__update({
      vehicle                  = vehicle
      vehicleRespawnsBySquad   = comp.vehicleRespawnsBySquad
    })
    if (trySpawnVehicleSquad(spawnCtx)) {
      comp.vehicleRespawnsBySquad[spawnCtx.squadId].lastSpawnOnVehicleAtTime = get_sync_time()
      onSuccessfulSpawn(comp);
    }
  }
  else if (trySpawnSquad(spawnCtx))
    onSuccessfulSpawn(comp);
}

local comps = {
  comps_rw = [
    ["isFirstSpawn", ::ecs.TYPE_BOOL],
    ["squads.botCount", ::ecs.TYPE_INT],
    ["squads.spawnCount", ::ecs.TYPE_INT],
    ["squads.squadsCanSpawn", ::ecs.TYPE_BOOL],
    ["delayedSpawnSquad", ::ecs.TYPE_ARRAY],
    ["vehicleRespawnsBySquad", ::ecs.TYPE_ARRAY],
  ]

  comps_ro = [
    ["isDefaultArmies", ::ecs.TYPE_BOOL],
    ["armiesReceivedTime", ::ecs.TYPE_FLOAT],
    ["armiesReceivedTeam", ::ecs.TYPE_INT],
    ["armies" ::ecs.TYPE_OBJECT],
    ["scoring_player.firstSpawnTime", ::ecs.TYPE_FLOAT],
    ["shouldValidateSpawnRules", ::ecs.TYPE_BOOL],
  ]
}

::ecs.register_es("spawn_squad_es", {
  [CmdSpawnSquad] = onSpawnSquad,
}, comps)

::ecs.register_es("pending_vehicle_spawn_es", {
    [[::ecs.EventEntityCreated, ::ecs.EventComponentsAppear]] = @(evt, eid, comp) onPendingVehicleSpawned(comp.ownedBySquad, comp.canUseRespawnbaseType)
  },
  {
    comps_ro = [["ownedBySquad", ::ecs.TYPE_EID], ["canUseRespawnbaseType", ::ecs.TYPE_STRING]],
    comps_rq = ["vehicle"]
  },
  {tags = "server"}
)

::ecs.register_es("create_respawner_es", {
    [::ecs.sqEvents.CmdCreateRespawner] = @(evt, eid, comp) createRespawner(comp["team"], eid, false)
  },
  {comps_ro = [["team", ::ecs.TYPE_INT]]},
  {tags = "server"}
)
 