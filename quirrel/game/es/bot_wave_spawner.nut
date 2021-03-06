local { TEAM_UNASSIGNED } = require("team")
local random = require("dagor.random")
local {get_team_eid} = require("globals/common_queries.nut")
local {find_respawn_base_for_team} = require("game/utils/respawn_base.nut")
local {spawn} = require("game/utils/spawn_bot.nut")
local {fill_walkable_positions_around} = require("navmesh")

local botWaveTimerId = "botWaveTimerId"

local function onWaveTimer(evt, eid, comp) {
  local teamToSpawnFor = comp["team"]
  local respBaseTeam = ::ecs.get_comp_val(eid, "bot_spawner.respTeam", teamToSpawnFor)

  ::ecs.set_timer({eid=eid, id=botWaveTimerId, interval = comp["bot_spawner.wavePeriod"], repeat = false})
  local respBase = find_respawn_base_for_team(respBaseTeam)
  if (respBase == INVALID_ENTITY_ID)
    return

  if (teamToSpawnFor == TEAM_UNASSIGNED)
    return
  local teamEid = get_team_eid(teamToSpawnFor)
  if (teamEid == null)
    return

  local transform = ::ecs.get_comp_val(respBase, "transform")
  local attractPoints = comp["bot_spawner.attractPoints"].getAll()
  local spawnDist = comp["bot_spawner.attractDist"]
  local maxAlive = comp["bot_spawner.maxAlive"]
  local spawnedAliveEntities = comp["bot_spawner.spawnedAliveEntities"].getAll()
  if (maxAlive > 0) {
    local res = []
    foreach (v in spawnedAliveEntities){
      if (::ecs.get_comp_val(v, "isAlive", false))
        res.append(v)
    }
    spawnedAliveEntities = res
    if (spawnedAliveEntities.len() >= maxAlive)
      return
  }

  local wishPosition = attractPoints[random.grnd() % attractPoints.len()]
  local potentialPosition = array(1)
  if (fill_walkable_positions_around(wishPosition, potentialPosition, spawnDist, 1.0))
    spawn({
      spawnerEid = eid,
      teamEid = teamEid,
      team = teamToSpawnFor,
      template = comp["bot_spawner.template"],
      transform = transform,
      potentialPosition = potentialPosition,
      onBotSpawned = @(new_eid) ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventBotSpawned({ eid = new_eid }))
    })
}

local function onInit(evt,eid,comp){
  ::ecs.clear_timer({eid=eid, id=botWaveTimerId})
  ::ecs.set_timer({eid=eid, id=botWaveTimerId, interval=0.5, repeat=false})
}

local comps = {
  comps_rw  = [["bot_spawner.spawnedAliveEntities", ::ecs.TYPE_ARRAY]],
  comps_ro = [
    ["bot_spawner.attractPoints", ::ecs.TYPE_ARRAY],
    ["bot_spawner.attractDist", ::ecs.TYPE_FLOAT],
    ["bot_spawner.maxAlive", ::ecs.TYPE_INT, -1],
    ["team", ::ecs.TYPE_INT],
    ["bot_spawner.template",::ecs.TYPE_STRING],
    ["bot_spawner.wavePeriod",::ecs.TYPE_FLOAT],
    ["bot_spawner.shouldSpawnSquads", ::ecs.TYPE_BOOL, false],
  ]
}
::ecs.register_es("bot_spawner_timer_es", {
  Timer = onWaveTimer,
}, comps, {tags="server"})

::ecs.register_es("bot_spawner_on_spawn_es",
  {
    [::ecs.sqEvents.EventBotSpawned] = function(evt, eid, comp){
      comp["bot_spawner.spawnedAliveEntities"].append(evt.data.eid)
    }
  },
  {comps_rw  = [["bot_spawner.spawnedAliveEntities", ::ecs.TYPE_ARRAY]]},
  {tags="server"}
)

::ecs.register_es("bot_spawner_init_es", {
    onInit = onInit
  }, { comps_rq  = ["bot_spawner.spawnedAliveEntities", "bot_spawner.template"]},
  {tags="server"})


 