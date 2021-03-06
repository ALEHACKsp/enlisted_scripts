local {EventHeroChanged} = require("gameevents")

local respawnSelection = persist("squadState", @() Watched(INVALID_ENTITY_ID))

::ecs.register_es("respawn_selection_ui_es", {
  [["onChange", "onInit"]] = function(eid, comp) {
    respawnSelection.update(comp["respawner.chosenRespawn"])
  },
  [EventHeroChanged] = function onHeroChanged(evt, eid, comp) {
    respawnSelection.update(evt[0])
  }
}, {comps_track = [["respawner.chosenRespawn", ::ecs.TYPE_EID]], comps_rq = ["human_input"]})


return respawnSelection
 