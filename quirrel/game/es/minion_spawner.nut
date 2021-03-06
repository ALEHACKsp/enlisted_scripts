local {fill_walkable_positions_around} = require("navmesh")
local {TMatrix} = require("dagor.math")

local onWaveTimerQuery = ::ecs.SqQuery("onWaveTimerQuery", {comps_ro=["possessed", "team"], comps_rq=["player"]})

local function onWaveTimer(eid, comp){
  ::print("onWaveTimer")
  local teamToSpawnFor = ::ecs.get_comp_val(eid, "team")
  local minionTeam = ::ecs.get_comp_val(eid, "minion_spawner.spawnTeam")
  local allPositions = []
  local playerPositions = []
  local spawnDist = comp["minion_spawner.spawn_distance"]
  local spawnDistSq = spawnDist * spawnDist
  local playerDiff = 0
  onWaveTimerQuery.perform(function(playerEid, playerComp){
    local plrTeam = playerComp["team"]
    playerDiff += plrTeam == teamToSpawnFor ? 1 : plrTeam == minionTeam ? -1 : 0
    local peid = playerComp["possessed"]
    if (peid == INVALID_ENTITY_ID || !::ecs.get_comp_val(peid, "isAlive", false) || plrTeam != teamToSpawnFor)
      return

    local tm = ::ecs.get_comp_val(peid, "transform")
    if (tm==null) {
      return
    }
    local position = tm.getcol(3)
    playerPositions.append(position)
    local potentialPositions = array(comp["minion_spawner.min_wave_size"] * 2)
    if (fill_walkable_positions_around(position, potentialPositions, spawnDist, 1.0))
      foreach (pos in potentialPositions)
        allPositions.append({position = pos, weight = 0.0})
  })
  foreach (pos in allPositions) {
    foreach (playerPos in playerPositions) {
      local lenSq = (pos.position - playerPos).lengthSq()
      if (lenSq < spawnDistSq)
        pos.weight += lenSq - spawnDistSq
    }
  }
  allPositions.sort(@(a,b) a.weight <=> b.weight)
  if (allPositions.len() == 0)
    ::ecs.set_timer({eid=eid, id="wave_timer", interval = 0.5, repeat = false}) // fast retry
  else
    ::ecs.set_timer({eid=eid, id="wave_timer", interval = comp["minion_spawner.wave_period"], repeat = false})
  local baseSize = comp["minion_spawner.base_wave_size"]
  local diffSz = comp["minion_spawner.diff_wave_size"]
  local perPlayerSz = comp["minion_spawner.per_player_wave_size"]
  local template = comp["minion_spawner.template"]
  local wishNumber = baseSize + playerDiff * diffSz + playerPositions.len() * perPlayerSz
  for (local i = 0; i < ::min(allPositions.len(), wishNumber); ++i) {
    local transform = TMatrix()
    transform.setcol(3, allPositions[i].position.x, allPositions[i].position.y, allPositions[i].position.z)
    local comps = {
      transform = [transform, ::ecs.TYPE_MATRIX],
      team = [minionTeam, ::ecs.TYPE_INT],
    }
    ::ecs.g_entity_mgr.createEntity(template, comps)
  }
}

local function onInit(evt, eid, comp){
 ::ecs.clear_timer({eid=eid, id="wave_timer"})
 ::ecs.set_timer({eid=eid, id="wave_timer", interval = 0.5, repeat = false})
}

local comps = {
  comps_ro = [
    ["minion_spawner.wave_period", ::ecs.TYPE_FLOAT, 15.0],
    ["minion_spawner.base_wave_size", ::ecs.TYPE_INT, 1],
    ["minion_spawner.per_player_wave_size", ::ecs.TYPE_INT, 1],
    ["minion_spawner.diff_wave_size", ::ecs.TYPE_INT, 1],
    ["minion_spawner.template", ::ecs.TYPE_STRING],
    ["minion_spawner.min_wave_size", ::ecs.TYPE_INT, 1],
    ["minion_spawner.spawn_distance", ::ecs.TYPE_FLOAT],
    ["minion_spawner.spawnTeam", ::ecs.TYPE_INT]
  ]
}

::ecs.register_es("minion_spawner_es", {
  Timer = onWaveTimer
  onInit = onInit
}, comps, {tags = "server"})


 