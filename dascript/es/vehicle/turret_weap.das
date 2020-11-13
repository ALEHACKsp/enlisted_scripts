require turrets
require ecs
require ecs.common
require vehicle
require EnlistedWeapon
require game.utils.hero
require game.es.vehicle.vehicle_seats_common
require game.es.events
require dm


[es (tag=gameClient, REQUIRE=input_dot_enabled)]
def turret_update_turret_aim_point(info: UpdateStageInfoAct;
                                   local_controls_state: VehicleControlsState;
                                   var isTurretAimPosValid: bool&;
                                   var turretAimPos: float3&;
                                   turret_input_dot_aimPos: Point3List?)
  isTurretAimPosValid = false
  if (turret_input_dot_aimPos != null)
    for turretNo in iter_range(*turret_input_dot_aimPos)
      if can_control_turret(local_controls_state, turretNo)
        isTurretAimPosValid = true
        turretAimPos = (*turret_input_dot_aimPos)[turretNo]
        break


[es (after=turret_weap_apply_client_controls_es)]
def turret_weap_reset_shoot(evt: CmdPostPhysUpdate;
                            vehicle_seats_player_controls: VehicleSeatsPlayerControls;
                            var turret_aim_dot_shootFlag: BoolList&)
  if !evt.isForReal
    return
  for turretNo in iter_range(turret_aim_dot_shootFlag)
    var canControlTurret = false
    for controls in vehicle_seats_player_controls.data
      if can_control_turret(controls, turretNo)
        canControlTurret = true
        break
    if !canControlTurret
      turret_aim_dot_shootFlag[turretNo] = false;


[es (tag=server, REQUIRE=isAlive)]
def turret_weap_can_shoot_updater(evt: CmdPostPhysUpdate;
                                  var turret_can_shoot: TurretCanShoot&;
                                  damage_model: DamageModel;
                                  turret_dm_part_dot_barrelDm: ecs::IntList;
                                  turret_dm_part_dot_breechDm: ecs::IntList)
  if !evt.isForReal
    return
  assert(length(turret_dm_part_dot_barrelDm) == length(turret_dm_part_dot_breechDm))
  for turretNo in iter_range(turret_dm_part_dot_barrelDm)
    let barrelDmId = turret_dm_part_dot_barrelDm[turretNo]
    let breechDmId = turret_dm_part_dot_breechDm[turretNo]
    var canShoot = true
    if barrelDmId >= 0
      canShoot = int(get_rel_hp_fixed(damage_model.dmData, barrelDmId)) > 0
    if breechDmId >= 0 && canShoot
      canShoot = int(get_rel_hp_fixed(damage_model.dmData, breechDmId)) > 0
    set_can_shoot_turret(turret_can_shoot, turretNo, canShoot)


def get_dm_part_hp(damage_model: DamageModel; part_no, var_id: int): float
  return part_no >=0 && var_id >= 0 ? float(get_rel_hp_fixed(damage_model.dmData, part_no)) / float(MAX_REL_HP_FIXED) : 1.f;


[es (tag=server, REQUIRE=isAlive, before=turret_weap_can_shoot_updater)]
def update_turret_aim_drives_mult(evt: CmdPostPhysUpdate;
                                  turret_control: TurretControl;
                                  var turret_aim_drives_mult: TurretAimDrivesMult;
                                  damage_model: DamageModel;
                                  vehicle_mods_dot_maxHorDriveMult : float = 1.0;
                                  vehicle_mods_dot_maxVerDriveMult : float = 1.0;
                                  turret_drive_dm_part_dot_horDriveDm: ecs::IntList;
                                  turret_drive_dm_part_dot_verDriveDm: ecs::IntList)
  if !evt.isForReal
    return
  assert(length(turret_drive_dm_part_dot_horDriveDm) == length(turret_drive_dm_part_dot_verDriveDm))
  for turretNo in iter_range(turret_drive_dm_part_dot_horDriveDm)
    let params & = turret_control.params[turretNo]
    let horDriveRelHp = get_dm_part_hp(damage_model, turret_drive_dm_part_dot_horDriveDm[turretNo], params.yawSpeedMulVarId)
    let verDriveRelHp = get_dm_part_hp(damage_model, turret_drive_dm_part_dot_verDriveDm[turretNo], params.pitchSpeedMulVarId)
    set_aim_mult_yaw(turret_aim_drives_mult.states[turretNo], vehicle_mods_dot_maxHorDriveMult * horDriveRelHp)
    set_aim_mult_pitch(turret_aim_drives_mult.states[turretNo], vehicle_mods_dot_maxVerDriveMult * verDriveRelHp)