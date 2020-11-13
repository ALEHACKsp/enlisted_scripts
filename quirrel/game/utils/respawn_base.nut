local { TEAM_UNASSIGNED } = require("team")
local rndInstance = require("std/rand.nut")()
local is_teams_friendly = require("globals/is_teams_friendly.nut")
local {get_sync_time} = require("net")
local {logerr} = require("dagor.debug")
local dagorMath = require("dagor.math")
local {get_team_eid} = require("globals/common_queries.nut")

local baseQueryComps = {
  comps_ro = [
    ["transform", ::ecs.TYPE_MATRIX],
    ["active", ::ecs.TYPE_BOOL],
    ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["temporaryRespawnbase", ::ecs.TYPE_TAG, null],
  ]
}

local respbaseWithTypeComps = baseQueryComps.__merge({
  comps_ro = [].extend(baseQueryComps.comps_ro).append(["respawnbaseType", ::ecs.TYPE_STRING])
})

local respbaseQueryComps = baseQueryComps.__merge({
  comps_ro = [].extend(baseQueryComps.comps_ro).append(["lastSpawnOnTime", ::ecs.TYPE_FLOAT, -11.0]).append(["enemyReuseDelay", ::ecs.TYPE_FLOAT, 10.0])
  comps_rq = ["respbase"]
  comps_no = ["vehicleRespbase"]
})

local vehicleRespbaseQueryComps = baseQueryComps.__merge({
  comps_rq = ["vehicleRespbase"]
})

local respbaseWithTypeQuery = ::ecs.SqQuery("respbaseWithTypeQuery", respbaseWithTypeComps)
local respbaseQuery = ::ecs.SqQuery("respbaseQuery", respbaseQueryComps)
local vehicleRespbaseQuery = ::ecs.SqQuery("vehicleRespbaseQuery", vehicleRespbaseQueryComps)
local searchSafestQuery = ::ecs.SqQuery("searchSafestQuery", {comps_ro = [ ["isAlive", ::ecs.TYPE_BOOL], ["team", ::ecs.TYPE_INT], "transform"]})

local movingZoneQuery = ::ecs.SqQuery("movingZoneQuery", {comps_ro = ["moving_zone.sleepingTime", "moving_zone.sourcePos", "moving_zone.sourceRadius", "moving_zone.targetPos", "moving_zone.targetRadius", "moving_zone.startEndTime"] } )

local function get_closest_dist_sq(to_pos, positions) {
  local closestDistSq = null
  foreach (pos in positions) {
    local distSq = (pos - to_pos).lengthSq()
    if (distSq < closestDistSq || closestDistSq == null)
      closestDistSq = distSq
  }
  return closestDistSq
}

local function filter_pos_by_zone(positions) {
  movingZoneQuery.perform(
    function(eid, comp) {
      local startMoveTime = comp["moving_zone.startEndTime"].x
      local sleepTime = comp["moving_zone.sleepingTime"]
      local interpK = dagorMath.cvt(get_sync_time(), startMoveTime - sleepTime * 0.9, startMoveTime - sleepTime * 0.1, 1.0, 0.0) // 0.9 - 0.1
      local sourcePos = comp["moving_zone.sourcePos"]
      local sourceRad = comp["moving_zone.sourceRadius"]
      local targetPos = comp["moving_zone.targetPos"]
      local targetRad = comp["moving_zone.targetRadius"]
      local validCenter = sourcePos * interpK + targetPos * (1.0 - interpK)
      local validRadius = sourceRad * interpK + targetRad * (1.0 - interpK)
      positions = positions.filter(@(pos) (pos[1] - validCenter).lengthSq() < validRadius * validRadius)
    }
  )
  return positions
}

local function get_respawn_bases_impl(query, filter, filter_cb = @(...) true) {
  local respawnBases = []
  local tempRespawnBases = []
  query.perform(function(eid, comp){
    if (!filter_cb(comp))
      return
    local dst = comp.temporaryRespawnbase != null ? tempRespawnBases : respawnBases
    dst.append([eid, comp.transform.getcol(3), comp.team])
  }, filter);
  return tempRespawnBases.len() > 0 ? tempRespawnBases : respawnBases
}

local function get_friendly_entities(query, team_id, filter) {
  local friendlyEntities = []
  query.perform(function(eid, comp) {
    if (team_id != TEAM_UNASSIGNED && comp.team == team_id)
      friendlyEntities.append(comp.transform.getcol(3))
  }, filter);
  return friendlyEntities
}

local get_filter_by_team = @(team_id)
  @"and(active,or(eq(opt(team,{1}),{0}),eq(opt(team,{1}),{1})))".subst(team_id, TEAM_UNASSIGNED)

local function get_respawn_bases(query, team_id) {
  local validEntities = get_respawn_bases_impl(query, get_filter_by_team(team_id))
  if (validEntities.len() == 0) {
    logerr("No spawn bases found for team=unassigned|{0}, fallback to all available instead".subst(team_id))
    return get_respawn_bases_impl(query, null)
  }
  return validEntities
}

local get_random_respawn_base = @(arr)
  arr.len() != 0 ? arr[rndInstance.rint(0, arr.len() - 1)][0] : INVALID_ENTITY_ID

local find_respawn_base_for_team = @(team_id)
  get_random_respawn_base(get_respawn_bases(respbaseQuery, team_id))

local find_vehicle_respawn_base_for_team = @(team_id)
  get_random_respawn_base(get_respawn_bases_impl(vehicleRespbaseQuery, get_filter_by_team(team_id)))

local find_all_respawn_bases_for_team_with_type = @(team, respType)
  get_respawn_bases_impl(respbaseWithTypeQuery, get_filter_by_team(team), @(comp) comp.respawnbaseType == respType)

local function find_safest_respawn_base_impl(query, team_id, validEntities, enemyEntities) {
  local friendlyEntities = get_friendly_entities(query, team_id, get_filter_by_team(team_id))

  searchSafestQuery(function(eid, comp) {
    if (!is_teams_friendly(comp.team, team_id))
      enemyEntities.append(comp.transform.getcol(3))
    else
      friendlyEntities.append(comp.transform.getcol(3))
  },"and(isAlive,ne(team,{0}))".subst(TEAM_UNASSIGNED))

  if (enemyEntities.len() == 0 && friendlyEntities.len() == 0) // no enemies, no friends, choose random spawn
    return get_random_respawn_base(validEntities)

  local bestEffortBase = INVALID_ENTITY_ID
  local maxEnemyDistSq = 0.0
  local acceptableBases = []
  local minEnemyDistSq = 2500.0 // 50
  local maxFriendDistSq = 10000.0 // 100
  local topDistSq = 1e6 // 1000
  if (friendlyEntities.len() < 1) // if we have no friends - limit our spawns. Otherwise - do not do this!
    validEntities = filter_pos_by_zone(validEntities)
  foreach (baseEntity in validEntities) {
    local basePos = baseEntity[1]
    local enemyDistSq = get_closest_dist_sq(basePos, enemyEntities)
    local friendDistSq = get_closest_dist_sq(basePos, friendlyEntities)

    local baseEid = baseEntity[0]
    local baseTeam = baseEntity[2]
    if (team_id != TEAM_UNASSIGNED && baseTeam == team_id) {
      friendDistSq = 0.0
      bestEffortBase = baseEid
      maxEnemyDistSq = topDistSq
    }
    local friendIsCloseEnough = friendDistSq == null || friendDistSq < maxFriendDistSq
    if (enemyDistSq != null && enemyDistSq > maxEnemyDistSq) {
      bestEffortBase = baseEid
      maxEnemyDistSq = enemyDistSq
    }
    local enemyIsFarEnough = enemyDistSq == null || enemyDistSq > minEnemyDistSq
    if (friendIsCloseEnough && enemyIsFarEnough)
      acceptableBases.append(baseEid)
  }

  if (friendlyEntities.len() == 0 && bestEffortBase != INVALID_ENTITY_ID) // first spawn should try best effort
    return bestEffortBase
  if (acceptableBases.len() != 0)
    return acceptableBases[rndInstance.rint(0,acceptableBases.len()-1)]
  else if (bestEffortBase != INVALID_ENTITY_ID)
    return bestEffortBase

  return get_random_respawn_base(validEntities)
}

local function find_safest_respawn_base_for_team(team_id) {
  local validEntities = get_respawn_bases(respbaseQuery, team_id)
  if (validEntities.len() == 0)
    return INVALID_ENTITY_ID

  local curTime = get_sync_time()
  local enemyEntities = []
  respbaseQuery.perform(function(eid, comp) {
    if (comp.lastSpawnOnTime + comp.enemyReuseDelay > curTime)
      enemyEntities.append(comp.transform.getcol(3))
  },"and(active,and(ne(opt(team,{1}),{0}),ne(opt(team,{1}),{1})))".subst(team_id, TEAM_UNASSIGNED))

  return find_safest_respawn_base_impl(respbaseQuery, team_id, validEntities, enemyEntities);
}

local function find_vehicle_safest_respawn_base_for_team(team_id) {
  local validEntities = get_respawn_bases(vehicleRespbaseQuery, team_id)
  return validEntities.len() == 0 ? INVALID_ENTITY_ID : find_safest_respawn_base_impl(vehicleRespbaseQuery, team_id, validEntities, []);
}

local find_vehicle_respawn_base = @(team, safest)
  safest ?
    find_vehicle_safest_respawn_base_for_team(team) :
    find_vehicle_respawn_base_for_team(team)

local find_human_respawn_base = @(team, safest)
  safest ?
    find_safest_respawn_base_for_team(team) :
    find_respawn_base_for_team(team)

local function get_can_use_respawnbase_type(templName) {
  if (templName == null)
    return null
  local db = ::ecs.g_entity_mgr.getTemplateDB()
  local templ = db.getTemplateByName(templName)
  if (templ == null) {
    logerr($"Template '{templName}' not found in templates DB")
    return null
  }
  return templ.getCompValNullable("canUseRespawnbaseType")
}

local vehicleQuery = ::ecs.SqQuery("vehicleQuery", {
  comps_ro = [["team", ::ecs.TYPE_INT], ["isAlive", ::ecs.TYPE_BOOL], ["canUseRespawnbaseType", ::ecs.TYPE_STRING]]
  comps_rq = ["vehicle"]
})

local function count_vehicles_of_type(team, respawnbaseType) {
  local nowVehiclesOnSpawn = 0
  vehicleQuery(function(eid, comp) {
    if (team == comp.team && comp.isAlive && comp.canUseRespawnbaseType == respawnbaseType)
      nowVehiclesOnSpawn++
  })
  return nowVehiclesOnSpawn
}

local function is_vehicle_spawn_allowed_by_limit(team, respawnbaseType) {
  local bases = find_all_respawn_bases_for_team_with_type(team, respawnbaseType)
  if (bases.len() == 0)
    return false
  local limit = ::ecs.get_comp_val(bases[0][0], "maxVehicleOnSpawn", -1)
  if (limit < 0)
    return true
  local teamEid = get_team_eid(team) ?? INVALID_ENTITY_ID
  local pendingMap = ::ecs.get_comp_val(teamEid, "team.spawnPending") ?? {}
  local pending = pendingMap?[respawnbaseType]?.len() ?? 0
  local existing = count_vehicles_of_type(team, respawnbaseType)
  return pending + existing < limit
}

return {
  find_human_respawn_base = find_human_respawn_base
  find_vehicle_respawn_base = find_vehicle_respawn_base

  find_respawn_base_for_team = find_respawn_base_for_team
  find_safest_respawn_base_for_team = find_safest_respawn_base_for_team

  find_vehicle_respawn_base_for_team = find_vehicle_respawn_base_for_team
  find_vehicle_safest_respawn_base_for_team = find_vehicle_safest_respawn_base_for_team

  get_can_use_respawnbase_type = get_can_use_respawnbase_type
  get_random_respawn_base = get_random_respawn_base

  find_respawn_base_for_team_with_type = @(team, respType)
    get_random_respawn_base(find_all_respawn_bases_for_team_with_type(team, respType))

  find_all_respawn_bases_for_team_with_type = find_all_respawn_bases_for_team_with_type

  count_vehicles_of_type = count_vehicles_of_type

  is_vehicle_spawn_allowed_by_limit = is_vehicle_spawn_allowed_by_limit
}
 