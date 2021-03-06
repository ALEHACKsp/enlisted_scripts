local {EventEntityRevived, EventEntityResurrected, EventEntityDowned, EventEntityDied} = require("deathevents")
// do not really create fake entity for it. it's okay to enable/disable actions as is in current design
local onActionsEnable = @(val) function(evt, eid, comp) {
  comp["actions.enabled"] = val
}

local comps = {
  comps_rw = [
    ["actions.enabled", ::ecs.TYPE_BOOL]
  ]
}
::ecs.register_es("action_enabler_es", {
  [EventEntityDowned] = onActionsEnable(false),
  [EventEntityDied] = onActionsEnable(false),
  [EventEntityRevived] = onActionsEnable(true),
  [EventEntityResurrected] = onActionsEnable(true),
}, comps)
 