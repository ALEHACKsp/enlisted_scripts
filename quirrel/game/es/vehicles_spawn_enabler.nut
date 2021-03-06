local {find_respawn_base_for_team_with_type, get_can_use_respawnbase_type, count_vehicles_of_type} = require("game/utils/respawn_base.nut")
local cq = require("globals/common_queries.nut")

local respawnerComps = {
  comps_ro = [
    ["respawner.respTime", ::ecs.TYPE_FLOAT],
    ["respawner.respStartTime", ::ecs.TYPE_FLOAT, -1.0],
    ["respawner.canRespawnTime", ::ecs.TYPE_FLOAT, -1.0],
    ["respawner.respEndTime", ::ecs.TYPE_FLOAT, -1.0],
    ["in_spawn", ::ecs.TYPE_BOOL, false],
  ]
  comps_rw = [
    ["respawner.vehicleRespawnsBySquad", ::ecs.TYPE_ARRAY]
  ]
}

local respawnerQuery = ::ecs.SqQuery("respawnerQuery", respawnerComps)
local playerQuery = ::ecs.SqQuery("playerQuery", {
  comps_ro = [
    ["team", ::ecs.TYPE_INT],
    ["armies", ::ecs.TYPE_OBJECT]
  ],
  comps_rw = [
    ["vehicleRespawnsBySquad", ::ecs.TYPE_ARRAY]
  ]
})

local function gatherAllRespawnbaseTypesInSquads(squads) {
  local respTypes = {}
  foreach (i, squad in squads) {
    local respType = get_can_use_respawnbase_type(squad?.curVehicle.gametemplate)
    if (respType != null)
      if (respType in respTypes)
        respTypes[respType].append(i)
      else
        respTypes[respType] <- [i]
  }
  return respTypes
}

local function onTimerChanged(evt, eid, comp) {
  local vehicleRespawnsBySquad = comp["respawner.vehicleRespawnsBySquad"].getAll()

  foreach (item in vehicleRespawnsBySquad) {
    item.respInVehicleEndTime = -1.0
    item.maxSpawnVehiclesOnPoint = -1
  }

  local playerEid = cq.find_connected_player_that_possess(eid)
  playerQuery.perform(playerEid, function(eid, playerComps) {
    local playerTeam = playerComps["team"]
    local teamEid = cq.get_team_eid(playerTeam) ?? INVALID_ENTITY_ID
    local teamArmy = ::ecs.get_comp_val(teamEid, "team.army")
    local armyData = playerComps?.armies[teamArmy]
    local playerVehicleRespawnsBySquad = playerComps["vehicleRespawnsBySquad"].getAll()

    vehicleRespawnsBySquad = array(playerVehicleRespawnsBySquad.len()).map(@(_, i) {
      respInVehicleEndTime = -1.0
      maxSpawnVehiclesOnPoint = -1
    })

    foreach (respType, squadIndices in gatherAllRespawnbaseTypesInSquads(armyData?.squads ?? [])) {
      local baseEid = find_respawn_base_for_team_with_type(playerTeam, respType)
      if (baseEid == INVALID_ENTITY_ID)
        continue
      local spawnFreq = ::ecs.get_comp_val(baseEid, "respTime", 0)
      local maxSpawnVehiclesOnPoint = ::ecs.get_comp_val(baseEid, "maxVehicleOnSpawn", 0)

      if (count_vehicles_of_type(playerTeam, respType) < maxSpawnVehiclesOnPoint)
        maxSpawnVehiclesOnPoint = -1

      foreach (i in squadIndices) {
        local lastSpawnOnVehicleAtTime = playerVehicleRespawnsBySquad[i].lastSpawnOnVehicleAtTime
        local timeToSpawn = spawnFreq != 0 && lastSpawnOnVehicleAtTime != 0 ? lastSpawnOnVehicleAtTime + spawnFreq : -1

        vehicleRespawnsBySquad[i].maxSpawnVehiclesOnPoint = maxSpawnVehiclesOnPoint
        vehicleRespawnsBySquad[i].respInVehicleEndTime = timeToSpawn

        playerVehicleRespawnsBySquad[i].nextSpawnOnVehicleInTime = timeToSpawn
      }
    }

    playerComps["vehicleRespawnsBySquad"] = playerVehicleRespawnsBySquad
  })

  comp["respawner.vehicleRespawnsBySquad"] = vehicleRespawnsBySquad
}

local function onVehiclesCountChanged(evt, eid, comp) {
  respawnerQuery.perform(function(spawnerEid, spawnerComp){
      onTimerChanged(evt, spawnerEid, spawnerComp)
  })
}

::ecs.register_es("vehicles_spawn_enabler_es", {
  [[::ecs.sqEvents.EventEntityActivate, "onDestroy", "onInit", ::ecs.EventComponentChanged]] = onTimerChanged,
}, respawnerComps, {tags="server", track = "in_spawn,respawner.respEndTime,respawner.respStartTime,respawner.canRespawnTime"})

::ecs.register_es("vehicles_count_changed_es", {
  [["onInit", "onChange"]] = onVehiclesCountChanged,
}, {
  comps_ro    = [["team", ::ecs.TYPE_INT], ["canUseRespawnbaseType", ::ecs.TYPE_STRING]]
  comps_track = [["isAlive", ::ecs.TYPE_BOOL]]
  comps_rq    = ["vehicle"]
}, {tags="server"}) 