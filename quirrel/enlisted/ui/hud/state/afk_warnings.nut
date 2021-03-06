local {playerEvents} = require("ui/hud/state/eventlog.nut")

::ecs.register_es("afk_ui_es", {
  [::ecs.sqEvents.AFKShowWarning] = @(evt, eid, comp) playerEvents.pushEvent({text = loc("isAfkWarning"), ttl = 15}),
  [::ecs.sqEvents.AFKShowDisconnectWarning] = @(evt, eid, comp) playerEvents.pushEvent({text = loc("isKickedSoon"), ttl = 15})
}, { comps_rq=["player"] }, { tags="gameClient" }) 