require ecs
require app
require math
require math.base
require game.utils.hero
require EnlistedWalkerai
require game.es.events
require common_shooter.es.common_shooter_events
require DagorMathUtils
require DaWeaponProps
require DaWeapons
require Gun
require EnlistedWeapon
require EnlistedHuman
require HumanPhys
require EnlistedPhys
require GamePhys
require PhysVars
require EnlistedDeviceAnim
require common_shooter.es.mortar.mortar_common

def start_mortar_mode(ownerEid : ecs::EntityId const)
  setOptional(ownerEid, "human_weap.mortarMode", true)
  sendEvent(ownerEid, [[CmdOpenMapForMortar]])

[es (REQUIRE=mortar)]
def mortar_triggered(evt : CmdWeapPhysUpdate;
                     gun_dot_ammo : int;
                     var mortar_dot_shootPressed : bool&)
  if !evt.isForReal || gun_dot_ammo <= 0
    return

  if evt.gctrl.shoot
    if !mortar_dot_shootPressed
      mortar_dot_shootPressed = true
  elif mortar_dot_shootPressed
    mortar_dot_shootPressed = false
    start_mortar_mode(evt.owner)

def start_fire_animation(var device_animation_dot_fireAt : float&; device_animation_dot_startAt : float)
  if device_animation_dot_fireAt < device_animation_dot_startAt
    device_animation_dot_fireAt = get_sync_time()

[es]
def mortar_strike(evt : CmdStartMortarStrikeAtPos; human_weap_dot_currentGunEid : EntityId)
  query(human_weap_dot_currentGunEid) <| $ [es (REQUIRE=mortar)] (var mortar_dot_targetPos : float3&; var mortar_dot_targetAcquiredFlag : bool&)
    mortar_dot_targetPos = evt.pos
    mortar_dot_targetAcquiredFlag = true

[es (tag=server)]
def mortar_map_closed(evt : EventMortarMapClosed; eid : ecs::EntityId; var human_weap_dot_mortarMode : bool&)
  if evt.active
    sendEvent(eid, [[CmdStartMortarStrikeAtPos pos=evt.targetPos]])
  else
    human_weap_dot_mortarMode = false

[es (track=(human_weap_dot_currentGunSlot, human_weap_dot_gunEids), REQUIRE=(human_weap_dot_currentGunSlot, human_weap_dot_gunEids))]
def exit_mortar_mod_on_weapon_switch(evt : Event;
                                     eid: EntityId;
                                     human_weap_dot_mortarMode : bool)
  if human_weap_dot_mortarMode
    sendEvent(eid, [[EventMortarMapClosed active=false, targetPos=float3()]])

[es (track=human_weap_dot_mortarMode)]
def mortar_animation_start_end_control(evt : Event;
                                       human_weap_dot_gunEids : ecs::EidList;
                                       human_weap_dot_curGunSlot : int;
                                       human_weap_dot_mortarMode : bool)
  let weapEid = human_weap_dot_gunEids[human_weap_dot_curGunSlot]
  query(weapEid) <| $ [es (REQUIRE=mortar)] (var device_animation_dot_isActive : bool&;
                                             var device_animation_dot_startAt : float&;
                                             var device_animation_dot_endAt : float&)
    if human_weap_dot_mortarMode
      device_animation_dot_isActive = true
      device_animation_dot_startAt = get_sync_time()
    else
      device_animation_dot_endAt = get_sync_time()

[es (tag=gameClient, before=human_lock_person_view_es, track=human_weap_dot_mortarMode, REQUIRE=hero)]
def mortar_mode_change_on_client(evt:Event;
                                 eid, possessedByPlr : ecs::EntityId;
                                 human_weap_dot_currentGunEid : EntityId;
                                 human_weap_dot_mortarMode : bool;
                                 var radioMode_dot_prevPose : int&)
  if human_weap_dot_mortarMode
    radioMode_dot_prevPose = human_input_get_stand_state(eid)
    human_input_set_stand_state(eid, int(HumanPhysControlType HCT_CROUCH))
  elif radioMode_dot_prevPose >= 0
    human_input_set_stand_state(eid, radioMode_dot_prevPose)
  sendEventImmediate(possessedByPlr, [[CmdSwitchCameraByEntity index=0, camNamesEid=human_weap_dot_mortarMode ? human_weap_dot_currentGunEid : eid]])

def reload(owner_eid : ecs::EntityId;
           gun_eid : ecs::EntityId;
           at_time : float;
           dt : float)
  sendEvent(owner_eid, [[CmdRequestReload atTime=at_time - dt, gunEid= gun_eid]])

[es]
def mortar_phys(evt : CmdWeapPhysUpdate;
                eid : ecs::EntityId;
                gun_dot_curShellId : ShellPropIds;
                mortar_dot_targetPos : float3;
                device_animation_dot_startAt : float;
                device_anim_dot_state : int;
                var mortar_dot_lastValidShootPos : float3&;
                var mortar_dot_gunDir : float3&;
                var gun_dot_ammo : int&;
                var gun : IGunHolder;
                var mortar_dot_targetAcquiredFlag : bool&;
                var mortar_dot_fireFlag : bool&;
                var device_animation_dot_fireAt : float&)
  if !evt.isForReal
    return

  if gun_dot_ammo == 0
    reload(evt.owner, eid, evt.atTime, evt.dt)

  var gctrl = evt.gctrl
  let isShootPressed = gctrl.shoot
  if gctrl.shoot && evt.gloc.gunPos != null
    mortar_dot_lastValidShootPos = *(evt.gloc.gunPos)

  gctrl.shoot = mortar_dot_fireFlag
  let isInMortarMode = get_bool(evt.owner, "human_weap.mortarMode") ?? false
  let isDeviceReady = device_anim_dot_state == int(DeviceAnimState DEVICE_STATE_USE) || device_anim_dot_state == int(DeviceAnimState DEVICE_STATE_FIRE)
  let updateGun = gun_dot_ammo > 0 && isInMortarMode && isDeviceReady && int(gun_dot_curShellId.shellId) >= 0
  let shouldStartAnimation = mortar_dot_targetAcquiredFlag
  mortar_dot_fireFlag = false
  mortar_dot_targetAcquiredFlag = false

  var gunInput : GunInput
  gunInput.atTime = evt.atTime;
  gunInput.isForReal = evt.isForReal;
  gunInput.rndSeed = phys_time_to_seed(evt.atTime);
  gunInput.curShellId = gun_dot_curShellId;

  if isShootPressed && isInMortarMode
    sendEvent(evt.owner, [[EventMortarMapClosed active=true, targetPos=mortar_dot_targetPos]])

  let isLastShootPosValid = gctrl.shoot && length_sq(mortar_dot_lastValidShootPos) > 0.0
  let startPos = isLastShootPosValid ? mortar_dot_lastValidShootPos : get_shoot_pos(gun, evt.gloc)

  if updateGun && calculate_arc_high_start_dir(startPos, mortar_dot_targetPos, get_shell_speed(gun_dot_curShellId) , mortar_dot_gunDir)
    gun_update(gun, gunInput, gun_dot_ammo, gctrl, mortar_dot_gunDir, mortar_dot_gunDir, startPos)
    if shouldStartAnimation
      start_fire_animation(device_animation_dot_fireAt, device_animation_dot_startAt)
    return

  gctrl.shoot = false
  gun_update(gun, gunInput, gun_dot_ammo, gctrl, evt.gloc)

[es]
def mortar_on_device_shoot(evt : EventOnDeviceShoot; var mortar_dot_fireFlag : bool&)
  mortar_dot_fireFlag = true

[es (tag=server, track=gun_dot_curShellId)]
def mortar_init_distance_limit(evt : Event;
                               gun_dot_curShellId : ShellPropIds;
                               var mortar_dot_distanceLimit : float&;
                               mortar_dot_distanceLimitMargin : float = 1.0)
  let speed = get_shell_speed(gun_dot_curShellId)
  let g = gravity()
  if g != 0.0
    mortar_dot_distanceLimit = (speed * speed / g) - mortar_dot_distanceLimitMargin

[es (track=(isDowned,isAlive))]
def mortar_exit_on_downed(evt : Event; isDowned : bool; isAlive : bool; var human_weap_dot_mortarMode : bool&)
  if isDowned || !isAlive
    human_weap_dot_mortarMode = false

[es (tag=server, track=possessedByPlr)]
def mortar_exit_if_non_player(evt : Event; possessedByPlr : EntityId; var human_weap_dot_mortarMode : bool&)
  if !possessedByPlr
    human_weap_dot_mortarMode = false

[es (on_event=(EventEntityCreated,EventComponentsAppear), REQUIRE=mortar)]
def mortar_register_pitch_var(evt : Event; mortar_dot_pitchPhysVarName : string; var phys_vars : PhysVars; var mortar_dot_pitchPhysVarId : int&)
  mortar_dot_pitchPhysVarId = register_var(phys_vars, mortar_dot_pitchPhysVarName, 0.0)

[es (tag=gameClient, track=mortar_dot_gunDir)]
def mortar_update_local_pitch(evt : Event; gun_dot_owner : EntityId; mortar_dot_gunDir : float3; mortar_dot_pitchPhysVarId : int; var phys_vars : PhysVars)
  if gun_dot_owner != get_controlled_hero() || mortar_dot_pitchPhysVarId < 0
    return
  let pitch = rad_to_deg(dir_to_angles(mortar_dot_gunDir).y)
  set_var(phys_vars, mortar_dot_pitchPhysVarId, pitch)

[es (tag=gameClient, no_order)]
def mortar_update_remote_pitch(info : UpdateStageInfoAct;
                               eid : EntityId;
                               human_weap_dot_mortarMode : bool;
                               human_weap_dot_currentGunEid : EntityId;
                               human_net_phys : HumanActor)
  if !human_weap_dot_mortarMode || eid == get_controlled_hero()
    return
  query(human_weap_dot_currentGunEid) <| $ [es] (mortar_dot_pitchPhysVarId : int; var phys_vars : PhysVars)
    if mortar_dot_pitchPhysVarId < 0
      return
    let prevPitch = dir_to_angles(human_net_phys.phys.previousState.gunDir).y
    let curPitch = dir_to_angles(human_net_phys.phys.currentState.gunDir).y
    let interpk = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
    let pitchDeg = rad_to_deg(lerp(prevPitch, curPitch, interpk))
    set_var(phys_vars, mortar_dot_pitchPhysVarId, pitchDeg)