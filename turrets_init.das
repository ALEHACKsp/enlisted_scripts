require ecs
require ecs.common
require game.es.events
require vehicle
require turrets

[private]
def safe_resize(var arr_ref: auto?; size)
  if arr_ref != null
    resize(*arr_ref, size)

[private]
def safe_fill(var arr_ref: auto?; value_ref: auto?)
  if value_ref != null
    safe_fill(arr_ref, *value_ref)

[private]
def safe_fill(var arr_ref: auto?; value: auto)
  if arr_ref != null
    safe_fill(*arr_ref, value)

[private]
def safe_fill(var arr_ref: auto; value_ref: auto?)
  if value_ref != null
    safe_fill(arr_ref, *value_ref)

[private]
def safe_fill(var arr_ref: auto; value: auto)
  for i in iter_range(arr_ref)
    arr_ref[i] = value

[es (on_event=(EventEntityCreated, EventComponentsAppear), before=turret_control_create_guns_es)]
def turrets_init(evt: Event;
                 [[shared_comp]] turret_control_dot_turretInfo: Array;
                 var turret_control: TurretControl?;
                 var turret_state: TurretState?;
                 var turret_state_remote: TurretState?;
                 var turret_aim_drives_mult: TurretAimDrivesMult?;
                 var turret_shoot_to_pos: Point3List?;
                 var turret_recoil_start_time: ecs::FloatList?;
                 var turret_recoil_duration: ecs::FloatList?;
                 var turret_aim_active_var_id: ecs::IntList?;
                 var turret_aim_dot_shootAngles: Point2List?;
                 var turret_aim_dot_atTick: IntList?;
                 var turret_aim_dot_shootFlag: BoolList?;
                 var turret_aim_dot_shootDirWithCorrection: Point3List?;
                 var turret_aim_dot_shouldMoveByYaw: BoolList?;
                 var turret_aim_dot_shouldMoveByPitch: BoolList?;
                 var turret_dm_part_dot_barrelDm: IntList?;
                 var turret_dm_part_dot_breechDm: IntList?;
                 var turret_drive_dm_part_dot_horDriveDm: IntList?;
                 var turret_drive_dm_part_dot_verDriveDm: IntList?)
  let turretsCount = length(turret_control_dot_turretInfo)
  safe_resize(turret_aim_dot_shootAngles, turretsCount)
  safe_resize(turret_aim_dot_atTick, turretsCount)
  safe_resize(turret_aim_dot_shootFlag, turretsCount)
  safe_resize(turret_aim_dot_shootDirWithCorrection, turretsCount)
  safe_resize(turret_aim_dot_shouldMoveByYaw, turretsCount)
  safe_resize(turret_aim_dot_shouldMoveByPitch, turretsCount)
  safe_resize(turret_control?.params, turretsCount)
  safe_resize(turret_state?.states, turretsCount)
  safe_resize(turret_state_remote?.states, turretsCount)
  safe_resize(turret_aim_drives_mult?.states, turretsCount)
  safe_resize(turret_shoot_to_pos, turretsCount)
  safe_resize(turret_aim_active_var_id, turretsCount)
  safe_resize(turret_recoil_start_time, turretsCount)
  safe_resize(turret_recoil_duration, turretsCount)
  safe_resize(turret_dm_part_dot_barrelDm, turretsCount)
  safe_resize(turret_dm_part_dot_breechDm, turretsCount)
  safe_resize(turret_drive_dm_part_dot_horDriveDm, turretsCount)
  safe_resize(turret_drive_dm_part_dot_verDriveDm, turretsCount)

  safe_fill(turret_aim_active_var_id, -1)
  safe_fill(turret_recoil_start_time, 0.f)
  safe_fill(turret_recoil_duration, 0.f)

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_aimPos(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_aimPos: Point3List)
  resize(turret_input_dot_aimPos, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_aimAngles(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_aimAngles: Point2List)
  resize(turret_input_dot_aimAngles, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_zoom(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_zoom: FloatList; turret_input_dot_minZoom: float?)
  resize(turret_input_dot_zoom, length(turret_control_dot_turretInfo))
  safe_fill(turret_input_dot_zoom, turret_input_dot_minZoom)

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_shootFlag(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_shootFlag: BoolList)
  resize(turret_input_dot_shootFlag, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_isZoom(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_isZoom: BoolList)
  resize(turret_input_dot_isZoom, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_firstUpdate(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_firstUpdate: BoolList)
  resize(turret_input_dot_firstUpdate, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_moveTurretYaw(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_moveTurretYaw: FloatList)
  resize(turret_input_dot_moveTurretYaw, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_moveTurretPitch(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_moveTurretPitch: FloatList)
  resize(turret_input_dot_moveTurretPitch, length(turret_control_dot_turretInfo))

[es (on_event=(EventEntityCreated,EventComponentsAppear), before=turrets_init)]
def init_turret_input_dot_turretTriggers(evt: Event; [[shared_comp]] turret_control_dot_turretInfo: Array; var turret_input_dot_turretTriggers: IntList)
  resize(turret_input_dot_turretTriggers, length(turret_control_dot_turretInfo))