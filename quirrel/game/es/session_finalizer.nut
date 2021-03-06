local {exit_game} = require("app")
local {EventSessionFinished} = require("gameevents")
local {EventTeamRoundResult} = require("teamevents")

local function onRoundResult(evt, eid, comp) {
  if (comp["is_session_finalizing"])
    return
  comp["is_session_finalizing"] = true
  ::ecs.clear_timer({eid=eid, id="session_finalizing"})
  ::ecs.set_callback_timer(exit_game, comp["session_finalizer.timer"], false)
  ::ecs.g_entity_mgr.broadcastEvent(EventSessionFinished())
}

local comps = {
  comps_rw = [["is_session_finalizing", ::ecs.TYPE_BOOL]],
  comps_ro = [["session_finalizer.timer", ::ecs.TYPE_FLOAT, 10.0]]
}

::ecs.register_es("session_finalizer_es", {
    [EventTeamRoundResult] = onRoundResult,
}, comps)

 