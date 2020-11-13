require ecs
require ecs.common
require vehicle
require turrets
require EnlistedWeapon
require PhysVars
require game.utils.hero
require game.es.vehicle.vehicle_seats_common


[es (no_order)]
def turret_aim_activate_es (info: UpdateStageInfoAct;
                            var phys_vars:PhysVars;
                            turret_aim_active_var_id: IntList;
                            turret_aim_drives_mult: TurretAimDrivesMult;
                            turret_control: TurretControl;
                            vehicle_seats_player_controls: VehicleSeatsPlayerControls)
  for turretNo in iter_range(turret_aim_active_var_id)
    if turret_aim_active_var_id[turretNo] < 0
      continue
    var canTurretControl = false
    for controls in vehicle_seats_player_controls.data
      if can_control_turret(controls, turretNo)
        canTurretControl = true
        break
    let aimDrivesMult = turret_aim_drives_mult.states[turretNo].aimDrivesMult
    let params & = turret_control.params[turretNo]
    if params.yawSpeedMulVarId >= 0
      set_var(phys_vars, params.yawSpeedMulVarId, aimDrivesMult.x)
    if params.pitchSpeedMulVarId >= 0
      set_var(phys_vars, params.pitchSpeedMulVarId, aimDrivesMult.y)
    set_var(phys_vars, turret_aim_active_var_id[turretNo], canTurretControl ? 1.f : 0.f)
