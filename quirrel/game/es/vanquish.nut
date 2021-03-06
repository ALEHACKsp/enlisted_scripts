local {EventEntityResurrected, EventEntityDied} = require("deathevents")

local function onEntityDied(evt, eid, comp) {
  ::ecs.set_comp_val(eid, "isVanquished", true)
  ::ecs.set_timer({eid=eid, id="vanquish_timer", interval=15, repeat=false})
}

local function onEntityResurrected(evt, eid, comp) {
  ::ecs.clear_timer({eid=eid, id="vanquish_timer"})
}
local function onTimer(evt, eid, comp){
  ::ecs.set_comp_val(eid, "isVanquished", false)
}

::ecs.register_es("vanquish_es", {
    [EventEntityDied] = onEntityDied,
    [EventEntityResurrected] = onEntityResurrected,
    Timer = onTimer
  },
  {comps_rw = [ ["isVanquished", ::ecs.TYPE_BOOL],]},
  {tags="server"}
)

 