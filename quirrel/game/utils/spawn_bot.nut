local selectRandom = require("game/utils/random_list_selection.nut")

local customSpawn = null

local defaultSpawn = ::kwarg(function(teamEid, team, template, transform, potentialPosition, onBotSpawned) {
  local botTemplates = ::ecs.get_comp_val(teamEid, "team.botTemplates").getAll()
  local weaponTemplates = ::ecs.get_comp_val(teamEid, "team.weaponTemplates").getAll()

  local finalTemplate = ::ecs.makeTemplate({addTemplates = [selectRandom(botTemplates), selectRandom(weaponTemplates), template]})

  local comps = {
    "transform" : [transform, ::ecs.TYPE_MATRIX],
    "team" : [team, ::ecs.TYPE_INT],
    "spawn_immunity.timer" : [0.0, ::ecs.TYPE_FLOAT],
    "walker_agent.blackboard.wishPosition" : [potentialPosition[0], ::ecs.TYPE_POINT3],
    "walker_agent.blackboard.wishPositionSet" : [true, ::ecs.TYPE_BOOL],
  }
  ::ecs.g_entity_mgr.createEntity(finalTemplate, comps, onBotSpawned)
})

return {
  spawn = @(params) (customSpawn ?? defaultSpawn)(params)

  defaultSpawn = defaultSpawn
  setCustomSpawn = function(func) { customSpawn = func }
} 