require ecs
require EnlistedActor
require EnlistedHuman
require HumanPhys
require math
require math.base
require DagorMathUtils
require math.ang

let
  HALF_PI = PI * 0.5
  SAFE_HALF_PI = HALF_PI - 1e-3f

[es (after=after_net_phys_sync)]
def human_look_dir_camera_es(
    info : UpdateStageInfoAct;
    isCameraTarget : bool;
    human_net_phys : HumanActor;
    transform : float3x4&;
    camera_dot_gunAimOffset : float2;
    var camera_dot_shootOffset : float2&;
    var camera_dot_prevLookDir : float3&;
    var camera_dot_lookDir : float3&;
    camera_dot_shootOffsetTau : float = 0.05f;
    isAlive : bool = true;
    killer : EntityId = INVALID_ENTITY_ID)

  if !isCameraTarget
    return

  camera_dot_prevLookDir = camera_dot_lookDir

  if isAlive || killer == INVALID_ENTITY_ID
    let ct & = human_net_phys.phys.producedCT
    let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)

    var ang : float2
    if (int(human_net_phys.role) & int(RoleFlags URF_LOCAL_CONTROL)) != 0
      ang = dir_to_angles(ct.wishLookDir)
    else
      let lerpValue = lerp(human_net_phys.phys.previousState.headDir, human_net_phys.phys.currentState.headDir, float3(interpK))
      ang = dir_to_angles(lerpValue)

    var aimOffs = lerp(human_net_phys.phys.previousState.gunAimOffset, human_net_phys.phys.currentState.gunAimOffset, float2(interpK))
    aimOffs += camera_dot_gunAimOffset

    camera_dot_shootOffset = approach(camera_dot_shootOffset, aimOffs, info.dt, camera_dot_shootOffsetTau)
    ang += camera_dot_shootOffset

    ang.y = clamp(ang.y, -SAFE_HALF_PI, SAFE_HALF_PI)
    camera_dot_lookDir = angles_to_dir(ang)
  else
    let killerTm = get_TMatrix(killer, "transform")
    if killerTm != null
      camera_dot_lookDir = normalize((*killerTm)[3] - transform[3])

[es (after=human_look_dir_camera_es)]
def human_look_dir_camera_in_vehicle_es(info : UpdateStageInfoAct; isInVehicle, isAlive : bool; human_net_phys : HumanActor; var camera_dot_lookDir : float3&)

  if !isInVehicle || !isAlive
    return

  let ct & = human_net_phys.phys.producedCT
  var ang = dir_to_angles(ct.wishLookDir)
  ang.y = clamp(ang.y, -SAFE_HALF_PI, SAFE_HALF_PI)
  camera_dot_lookDir = angles_to_dir(ang)