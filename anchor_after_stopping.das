require ecs
require EnlistedShip
require Ship
require vehicle
require DagorMath
require math.base

[es (tag=server, no_order)]
def anchor_after_stopping(
  info : UpdateStageInfoAct;
  auto_anchor_dot_minSpeedForAnchor, auto_anchor_dot_delay : float;
  vehicle_seats_controls : VehicleSeatsControls;
  vehicle_seats_owners : VehicleSeatsOwners;
  var auto_anchor_dot_nextAnchorTime : float&;
  var ship_net_phys : ShipActor)

  var index = 0
  for control in vehicle_seats_controls.data
    if vehicle_seats_owners.data[index].eid != INVALID_ENTITY_ID
      auto_anchor_dot_nextAnchorTime = 0f
      ship_phys_set_anchor(ship_net_phys.phys, false)
      return
    index++

  let lowSpeed = length_sq(ship_net_phys.phys.currentState.velocity) <= square(auto_anchor_dot_minSpeedForAnchor)
  if !lowSpeed
    auto_anchor_dot_nextAnchorTime = 0f
    ship_phys_set_anchor(ship_net_phys.phys, false)
    return

  if auto_anchor_dot_nextAnchorTime <= 0f
    auto_anchor_dot_nextAnchorTime = info.curTime + auto_anchor_dot_delay
    return

  if info.curTime >= auto_anchor_dot_nextAnchorTime
    auto_anchor_dot_nextAnchorTime = 0f
    ship_phys_set_anchor(ship_net_phys.phys, true)
