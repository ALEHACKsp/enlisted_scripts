                                          

local artilleryStrikes = Watched([])

local function onEventEntityCreated(evt, eid, comp) {
  artilleryStrikes(@(list) list.append({pos = comp.transform.getcol(3), radius = comp["artillery_zone.radius"]}))
}

local function onEventEntityDestroyed(evt, eid, comp) {
  local removedPos = comp.transform.getcol(3)
  local idx = artilleryStrikes.value.findindex(@(it) (it.pos - removedPos).lengthSq() < 1.0)
  if (idx != null)
    artilleryStrikes.update(@(value) value.remove(idx))
}

::ecs.register_es("hud_artillery_zones_ui_es",
  {
    [::ecs.EventEntityCreated] = onEventEntityCreated,
    [::ecs.EventEntityDestroyed] = onEventEntityDestroyed
  },
  {
    comps_ro = [
      ["transform", ::ecs.TYPE_MATRIX],
      ["artillery_zone.radius", ::ecs.TYPE_FLOAT],
    ]
  }
)

return artilleryStrikes
 