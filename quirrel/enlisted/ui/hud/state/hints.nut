local {EventLevelLoaded} = require("gameevents")
local {playerEvents} = require("ui/hud/state/eventlog.nut")

::ecs.register_es("hints_ui_es",
  {
    [EventLevelLoaded] = function (evt, eid, comp) {
      local ttl = comp["hint.ttl"]
      local msg = comp["hint.message"]
      ::ecs.set_callback_timer(function() {
        playerEvents.pushEvent({text = ::loc(msg), ttl = ttl})
        ::ecs.g_entity_mgr.destroyEntity(eid)
      }, comp["hint.showTimeout"], false)
    }
  },
  { comps_ro=[["hint.message", ::ecs.TYPE_STRING], ["hint.showTimeout", ::ecs.TYPE_FLOAT], ["hint.ttl", ::ecs.TYPE_FLOAT]] },
  { tags="gameClient" }) 