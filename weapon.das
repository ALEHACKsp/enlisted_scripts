require ecs
require EnlistedWeapon
require vehicle

[generic]
def can_shoot_turret(turret_can_shoot: TurretCanShoot; turretNo : int)
  return (int(turret_can_shoot.state) & (1 << turretNo)) != 0

[generic]
def can_control_turret(local_controls_state : VehicleControlsState; turretNo : int)
  return (int(local_controls_state.turretsMask) & (1 << turretNo)) != 0

[generic]
def can_control_turrets(local_controls_state : VehicleControlsState)
  return int(local_controls_state.turretsMask) != 0

[generic]
def set_can_shoot_turret(var turret_can_shoot: TurretCanShoot&; turret_no: int; value: bool)
  let state = uint(turret_can_shoot.state)
  if value
    turret_can_shoot.state = uint8(state | (1u << uint(turret_no)))
  else
    turret_can_shoot.state = uint8(state & (~(1u << uint(turret_no))))
