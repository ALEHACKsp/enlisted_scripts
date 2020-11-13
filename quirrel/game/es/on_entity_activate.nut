local function onEntityActivate(evt, eid, comp) {
  comp.active = evt.data["activate"]
}

local comps = {
  comps_rw = [
    ["active", ::ecs.TYPE_BOOL]
  ]
}
::ecs.register_es("enity_activate_es", {
  [::ecs.sqEvents.EventEntityActivate] = onEntityActivate,
}, comps)

 