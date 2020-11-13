require ecs
require math
require math.base
require math.ang
require dm
require game.utils.hero
require game.utils.team
require DaWeaponProps
require BallisticsProps
require Plane
require EnlistedPlane
require EnlistedCamera
require DagorSystem
require DagorMath
require DaWeapons

[es (tag=gameClient, REQUIRE=forestallPos, on_event=EventComponentsAppear)]
def plane_target_forestall_log_props_missing(evt : Event; eid : EntityId; turret_control_dot_gunEids : EidList)
  if length(turret_control_dot_gunEids) < 1
    return
  let gunEid = turret_control_dot_gunEids[0]
  query(gunEid) <| $[es] (gun_dot_curShellId : ShellPropIds)
    let ballisticsProps = int(gun_dot_curShellId.ballisticsId) >= 0 ? get_projectile_props(int(gun_dot_curShellId.ballisticsId)) : null
    let shellStartProps = int(gun_dot_curShellId.shellId) >= 0 ? get_shell_start_props(int(gun_dot_curShellId.shellId)) : null

    if ballisticsProps == null
      logerr("Missing ProjectileProps required for forestall in template {getEntityTemplateName(eid)}. ballisticsId: {gun_dot_curShellId.ballisticsId}")
    if shellStartProps == null
      logerr("Missing ShellStartProps required for forestall in template {getEntityTemplateName(eid)}. shellId: {gun_dot_curShellId.shellId}")

def get_angle_and_dist_to_target(target_pos, forestall_pos, camera_pos, selector_dir : float3;
                                 var out_angle : float&; var out_dist : float&)
  var targetDir = target_pos - camera_pos
  out_dist = length(targetDir)
  targetDir *= safeinv(out_dist)
  let forestallDir = normalize(forestall_pos - camera_pos)

  let curAngleToForestall = safe_acos(dot(forestallDir, selector_dir))
  let curAngleToUnit = safe_acos(dot(targetDir, selector_dir))
  out_angle = min(curAngleToForestall, curAngleToUnit)

[es (tag=gameClient, REQUIRE=heroVehicle, no_order)]
def plane_target_forestall(info : UpdateStageInfoAct;
                           eid : EntityId;
                           transform : float3x4;
                           turret_control_dot_gunEids : EidList;
                           turretAimPos : float3;
                           plane_net_phys : PlaneActor?;
                           plane_input_dot_mouseAimEnabled : bool = false;
                           forestallMaxDist : float;
                           forestallCutoffAngle : float;
                           forestallDt : float = 0.02f;
                           forestallIterMax : int = 5;
                           forestallMaxTime : float = 60.0;
                           var forestallOpacity : float&;
                           var forestallPos : float3&;
                           var target_lock_dot_selectedEntity : EntityId&)
  let heroPlaneEid = eid
  let heroTeam = get_int(get_controlled_hero(), "team") ?? TEAM_UNASSIGNED
  if length(turret_control_dot_gunEids) < 1
    return

  query(turret_control_dot_gunEids[0]) <| $[es] (gun_dot_curShellId : ShellPropIds)
    let ballisticsProps = (int(gun_dot_curShellId.ballisticsId) >= 0 ?
                            get_projectile_props(int(gun_dot_curShellId.ballisticsId)) : null)
    let shellStartProps = (int(gun_dot_curShellId.shellId) >= 0 ?
                            get_shell_start_props(int(gun_dot_curShellId.shellId)) : null)

    if ballisticsProps == null || shellStartProps == null
      return

    let muzzleVelocity = shellStartProps.speed

    let shooterPos = plane_net_phys != null ? float3((*plane_net_phys).phys.visualLocation.P) : transform[3]
    let shooterVel = plane_net_phys != null ? float3((*plane_net_phys).phys.vel) : float3(0.0)

    let camItm = get_TMatrix(get_cur_cam_entity(), "transform")
    if camItm == null
      return
    let cameraPos = (*camItm)[3]

    let forestallSelectorDir = plane_input_dot_mouseAimEnabled ? normalize(turretAimPos - cameraPos) : (*camItm)[2]
    var minForestallAngle = forestallCutoffAngle

    var autoTarget = INVALID_ENTITY_ID
    var opacity = forestallOpacity
    var selectedPos = forestallPos

    query() <| $[es (REQUIRE=airplane)] (eid : EntityId;
                                         transform : float3x4;
                                         isAlive : bool;
                                         team : int;
                                         damage_model : DamageModel;
                                         plane_net_phys : PlaneActor)
      if !isAlive || eid == heroPlaneEid || is_teams_friendly(heroTeam, team)
        return

      let precisionSq = square(2.0 * damage_model.collisionData.boundingSphere.r)

      let targetPos = float3(plane_net_phys.phys.visualLocation.P)
      let targetVel = float3(plane_net_phys.phys.vel)
      let targetAcc = float3(plane_net_phys.phys.accel)

      var outShooterDir : float3
      var outFlightTime : float
      if !aim_projectile(*ballisticsProps, shooterPos, shooterVel, targetPos, targetVel, targetAcc, muzzleVelocity, precisionSq,
                         true, // bullet gravity
                         true, // air friction
                         forestallDt, forestallMaxTime, forestallIterMax, outShooterDir, outFlightTime)
        return

      let pos = shooterPos + outShooterDir * length((targetPos + targetVel * outFlightTime) - shooterPos)

      var angleToTarget, distToTarget : float
      get_angle_and_dist_to_target(transform[3], pos, cameraPos, forestallSelectorDir, angleToTarget, distToTarget)
      if angleToTarget >= 0.0 && angleToTarget <= minForestallAngle && distToTarget <= forestallMaxDist
        minForestallAngle = angleToTarget
        autoTarget = eid
        opacity = 1.0 - safediv(angleToTarget, forestallCutoffAngle)
        selectedPos = pos

    target_lock_dot_selectedEntity = autoTarget
    forestallPos = selectedPos
    forestallOpacity = opacity