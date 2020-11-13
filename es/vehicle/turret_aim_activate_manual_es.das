require ecs
require ecs.common
require vehicle
require turrets
require EnlistedWeapon
require PhysVars
require game.utils.hero
require game.es.vehicle.vehicle_seats_common

[es (after=turret_aim_activate_es, REQUIRE=manualTurretsControl)]
def turret_aim_activate_manual_es(info: UpdateStageInfoAct;
                                  var phys_vars:PhysVars;
                                  turret_aim_active_var_id:IntList;
                                  turret_aim_dot_shouldMoveByYaw:BoolList;
                                  turret_aim_dot_shouldMoveByPitch:BoolList)
  for turretNo in iter_range(turret_aim_active_var_id)
    if turret_aim_active_var_id[turretNo] < 0
      continue
    let shouldMoveByYaw = turret_aim_dot_shouldMoveByYaw[turretNo]
    let shouldMoveByPitch = turret_aim_dot_shouldMoveByPitch[turretNo]
    let canTurretControl = (get_var(phys_vars, turret_aim_active_var_id[turretNo]) > 0.f) && (shouldMoveByYaw || shouldMoveByPitch)
    set_var(phys_vars, turret_aim_active_var_id[turretNo], canTurretControl ? 1.f : 0.f)


[es (tag=gameClient, after=turret_aim_activate_es, REQUIRE=manualTurretsControl)]
def turret_aim_activate_manual_without_input_es(info: UpdateStageInfoAct;
                                                var phys_vars:PhysVars;
                                                local_controls_state:VehicleControlsState;
                                                turret_control:TurretControl;
                                                turret_aim_dot_shouldMoveByYaw:BoolList;
                                                turret_aim_dot_shouldMoveByPitch:BoolList)
  for turretNo in iter_range(turret_aim_dot_shouldMoveByYaw)
    if !can_control_turret(local_controls_state, turretNo)
      let shouldMoveByYaw   = turret_aim_dot_shouldMoveByYaw[turretNo]
      let shouldMoveByPitch = turret_aim_dot_shouldMoveByPitch[turretNo]
      let params & = turret_control.params[turretNo]
      if params.yawSpeedMulVarId >= 0
        set_var(phys_vars, params.yawSpeedMulVarId, shouldMoveByYaw ? 1.f : 0.f)
      if params.pitchSpeedMulVarId >= 0
        set_var(phys_vars, params.pitchSpeedMulVarId, shouldMoveByPitch ? 1.f : 0.f)
