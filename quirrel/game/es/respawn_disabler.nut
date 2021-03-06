local {EventOnMovingZoneDone, EventOnMovingZoneStarted} = require("gameevents")

local function shouldDisableResp(evt, eid, comp, zone_pos, zone_rad) {
  if (!comp.active)
    return false
  local respPos = comp.transform.getcol(3)
  return (respPos - zone_pos).lengthSq() >= zone_rad * zone_rad
}

local function onMovingZoneStarted(evt, eid, comp) {
  if (!comp.active)
    return
  local zoneEid = evt[0]
  local zonePos = ::ecs.get_comp_val(zoneEid, "moving_zone.targetPos")
  local zoneRad = ::ecs.get_comp_val(zoneEid, "moving_zone.targetRadius")
  if (shouldDisableResp(evt, eid, comp, zonePos, zoneRad))
    comp.active = false
}

local function onMovingZoneDone(evt, eid, comp) {
  if (!comp.active)
    return
  local zoneEid = evt[0]
  local zonePos = ::ecs.get_comp_val(zoneEid, "transform").getcol(3)
  local zoneRad = ::ecs.get_comp_val(zoneEid, "sphere_zone.radius")
  if (shouldDisableResp(evt, eid, comp, zonePos, zoneRad))
    comp.active = false
}


local comps = {
  comps_rw = [
    ["active", ::ecs.TYPE_BOOL]
  ]
  comps_ro = [
    ["transform", ::ecs.TYPE_MATRIX]
  ]
  comps_rq=["respbase"]
}

::ecs.register_es("respawn_base_disabler_es", {
  [EventOnMovingZoneStarted] = onMovingZoneStarted,
  [EventOnMovingZoneDone] = onMovingZoneDone,
}, comps)
 