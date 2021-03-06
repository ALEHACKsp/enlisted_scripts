local chooseRandom = require("std/rand.nut").chooseRandom
local {defaultSpawn, setCustomSpawn} = require("game/utils/spawn_bot.nut")
local {mkComps} = require("squad_spawn.nut")
local defaultProfile = require("enlisted/game/data/default_client_profile.nut")
local logerr = require("dagor.debug").logerr

local squadSpawn = ::kwarg(function(teamEid, team, template, transform, potentialPosition, onBotSpawned) {
  local teamArmy = ::ecs.get_comp_val(teamEid, "team.army")
  local teamSpawnBotArmy = ::ecs.get_comp_val(teamEid, "team.spawnBotArmy")
  local squad = (defaultProfile?[teamArmy] ?? defaultProfile?[teamSpawnBotArmy])?.squads[0].squad
  if (!squad) {
    logerr($"Unable to spawn bot for squad because of not found squad data for team {teamArmy} or {teamSpawnBotArmy}")
    return
  }

  local soldier = chooseRandom(squad)
  local aiAttrs = {
    ["transform"] = [transform, ::ecs.TYPE_MATRIX],
    ["team"] = team,
    ["beh_tree.enabled"] = true,
    ["human_weap.infiniteAmmoHolders"] = true,
    ["human_net_phys.isSimplifiedPhys"] = true,
    ["spawn_immunity.timer"] = [0.0, ::ecs.TYPE_FLOAT],
    ["walker_agent.blackboard.wishPosition"] = [potentialPosition[0], ::ecs.TYPE_POINT3],
    ["walker_agent.blackboard.wishPositionSet"] = true,
  }

  aiAttrs.
    __update(mkComps(soldier))

  ::ecs.g_entity_mgr.createEntity("+".concat(soldier.gametemplate, template), aiAttrs, onBotSpawned)
})

local function spawn(params) {
  local spawnerEid = params?.spawnerEid ?? INVALID_ENTITY_ID
  if (::ecs.get_comp_val(spawnerEid, "bot_spawner.shouldSpawnSquads") ?? false)
    squadSpawn(params)
  else
    defaultSpawn(params)
}

setCustomSpawn(spawn) 