require ecs
require app
require math
require DagorMath
require PhysVars
require EnlistedWeapon
require EnlistedHumanAnim
require EnlistedDeviceAnim
require EnlistedHuman
require HumanPhys
require game.es.events
require AnimV20
require AnimatedPhys

def set_device_state(var phys_vars : PhysVars;
                     var device_anim_dot_state: int&;
                     var device_anim_dot_progress: float&;
                     device_anim_dot_stateVarId : int;
                     device_anim_dot_progressVarId : int;
                     device_anim_dot_states : ecs::IntList;
                     state : DeviceAnimState;
                     progress : float)
  if device_anim_dot_stateVarId >= 0
    let stateEnum = device_anim_dot_states[device_anim_dot_state]
    set_var(phys_vars, device_anim_dot_stateVarId, float(stateEnum));
  if device_anim_dot_progressVarId >= 0
    set_var(phys_vars, device_anim_dot_progressVarId, progress);
  device_anim_dot_state = int(state)
  device_anim_dot_progress = progress

def set_backpack_state(var phys_vars : PhysVars;
                       var device_anim_dot_state: int&;
                       var device_anim_dot_progress: float&;
                       device_anim_dot_stateVarId : int;
                       device_anim_dot_progressVarId : int;
                       device_anim_dot_states : ecs::IntList;
                       progress : float)
  set_device_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states,
                   DeviceAnimState DEVICE_STATE_DISABLED, progress)

[es (track=human_weap_dot_currentGunSlot)]
def device_animation_check_unequipped(evt : Event; human_weap_dot_currentGunSlot : int; human_net_phys : HumanActor; human_weap_dot_gunEids : ecs::EidList)
  let curState = human_net_phys.phys.currentState.weapEquipState.curState
  if curState != HUWeaponEquipState EES_EQUIPED
    return
  let curSlot = human_weap_dot_currentGunSlot
  for slot,weapEid in iter_range(human_weap_dot_gunEids),human_weap_dot_gunEids
    if slot == curSlot
      continue
    query(weapEid) <| $ [es] (var phys_vars : PhysVars;
                              var device_anim_dot_state: int&;
                              var device_anim_dot_progress: float&;
                              device_anim_dot_stateVarId : int;
                              device_anim_dot_progressVarId : int;
                              device_anim_dot_states : ecs::IntList)
      set_backpack_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states, 0.0)

[es (no_order)]
def device_animation_equip(info : UpdateStageInfoAct;
                           human_weap_dot_gunEids : ecs::EidList;
                           human_anim : HumanAnimCtx;
                           human_net_phys : HumanActor;
                           phys_vars : PhysVars)
  let prevState = human_net_phys.phys.previousState.weapEquipState.curState
  let curState = human_net_phys.phys.currentState.weapEquipState.curState
  let curSlot = int(human_net_phys.phys.currentState.weapEquipState.curSlot)
  let nextSlot = int(human_net_phys.phys.currentState.weapEquipState.nextSlot)

  let progress = 1.0 - get_var(phys_vars, human_anim.changeWeaponVarId)

  ecs::query(human_weap_dot_gunEids[nextSlot]) <| $ [es] (var phys_vars : PhysVars;
                                                          var device_anim_dot_state: int&;
                                                          var device_anim_dot_progress: float&;
                                                          device_anim_dot_stateVarId : int;
                                                          device_anim_dot_progressVarId : int;
                                                          device_anim_dot_states : ecs::IntList)
    if curState == HUWeaponEquipState EES_EQUIPING
      set_backpack_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states, progress)

  ecs::query(human_weap_dot_gunEids[curSlot]) <| $ [es] (var phys_vars : PhysVars;
                                                         var device_anim_dot_state: int&;
                                                         var device_anim_dot_progress: float&;
                                                         device_anim_dot_stateVarId : int;
                                                         device_anim_dot_progressVarId : int;
                                                         device_anim_dot_states : ecs::IntList)
    if curState == HUWeaponEquipState EES_HOLSTERING
      set_backpack_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states, progress)
    elif prevState == HUWeaponEquipState EES_HOLSTERING
      set_backpack_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states, 0.0)
    elif curState == HUWeaponEquipState EES_EQUIPED && prevState != HUWeaponEquipState EES_EQUIPED
      set_backpack_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states, 1.0)

def post_state(atTime : float;
               device_animation_dot_postTime : float;
               device_animation_dot_endAt : float;
               var device_animation_dot_isActive : bool&;
               var progress : float&;
               var state : DeviceAnimState&)
  let postEndTime = device_animation_dot_endAt + device_animation_dot_postTime
  progress = cvt(atTime, device_animation_dot_endAt, postEndTime, 0.0, 1.0);
  state = DeviceAnimState DEVICE_STATE_POST;
  if atTime > postEndTime
    device_animation_dot_isActive = false

def prepare_state(atTime : float;
                  loopStart : float;
                  device_animation_dot_startAt : float;
                  var progress : float&;
                  var state : DeviceAnimState&)
  progress = cvt(atTime, device_animation_dot_startAt, loopStart, 0.0, 1.0);
  state = DeviceAnimState DEVICE_STATE_PREPARE;

def fire_state(eid : EntityId;
               atTime : float;
               dt : float;
               device_animation_dot_firePrepareTime : float;
               device_animation_dot_firePostTime : float;
               var device_animation_dot_fireAt : float&;
               var progress : float&;
               var state : DeviceAnimState&)
  let firePrepareAt = device_animation_dot_fireAt + device_animation_dot_firePrepareTime
  let fireEndAt = firePrepareAt + device_animation_dot_firePostTime
  state = DeviceAnimState DEVICE_STATE_FIRE;
  if atTime < firePrepareAt
    progress = cvt(atTime, device_animation_dot_fireAt, firePrepareAt, 0.0, 0.5)
    return
  if atTime - dt <= firePrepareAt
    sendEvent(eid, [[EventOnDeviceShoot]])
  if atTime < fireEndAt
    progress = cvt(atTime, firePrepareAt, fireEndAt, 0.5, 1.0)
  else
    device_animation_dot_fireAt = -1.0

def use_state(atTime : float;
              loopStart : float;
              device_animation_dot_loopTime : float;
              var progress : float&;
              var state : DeviceAnimState&)
  let loop = (atTime - loopStart) / device_animation_dot_loopTime
  progress = loop - floor(loop);
  state = DeviceAnimState DEVICE_STATE_USE;

[es (no_order)]
def device_animation(act : ecs::UpdateStageInfoAct;
                     human_weap_dot_gunEids : ecs::EidList;
                     human_weap_dot_currentGunSlot : int;
                     human_net_phys : HumanActor;
                     device_anim_dot_stateVarId : int;
                     device_anim_dot_progressVarId : int;
                     device_anim_dot_states : ecs::IntList;
                     isTpsView : bool = false;
                     var device_anim_dot_state: int&;
                     var device_anim_dot_progress: float&;
                     var phys_vars : PhysVars)

  let curState = human_net_phys.phys.currentState.weapEquipState.curState
  if curState != HUWeaponEquipState EES_EQUIPED
    return

  if human_weap_dot_currentGunSlot < 0
    return

  var humanDeviceAnimState : int& = device_anim_dot_state
  var humanDeviceAnimProgress : float& = device_anim_dot_progress
  var humanPhysVars : PhysVars& = phys_vars
  let humanDeviceStateVarId : int& = device_anim_dot_stateVarId
  let humanDeviceProgressVarId : int& = device_anim_dot_progressVarId
  let humanDeviceStates : ecs::IntList& = device_anim_dot_states

  let weapEid = human_weap_dot_gunEids[human_weap_dot_currentGunSlot]
  query(weapEid) <| $ [es] (eid: EntityId;
                            device_anim_dot_stateVarId : int;
                            device_anim_dot_progressVarId : int;
                            device_anim_dot_states : ecs::IntList;
                            device_animation_dot_prepareTime : float;
                            device_animation_dot_loopTime : float;
                            device_animation_dot_firePrepareTime : float;
                            device_animation_dot_firePostTime : float;
                            device_animation_dot_postTime : float;
                            device_animation_dot_startAt : float;
                            device_animation_dot_endAt : float;
                            device_anim_dot_isFpvVarId : int = -1;
                            var device_anim_dot_state: int&;
                            var device_anim_dot_progress: float&;
                            var device_animation_dot_fireAt : float&;
                            var device_animation_dot_isActive : bool&;
                            var phys_vars : PhysVars)
    let atTime = get_sync_time()
    var progress = 1.0
    var state = DeviceAnimState DEVICE_STATE_DISABLED
    if device_animation_dot_isActive
      let loopStart = device_animation_dot_startAt + device_animation_dot_prepareTime
      if device_animation_dot_endAt > device_animation_dot_startAt && atTime > device_animation_dot_endAt
        post_state(atTime, device_animation_dot_postTime, device_animation_dot_endAt,
            device_animation_dot_isActive, progress, state)
      elif atTime < loopStart
        prepare_state(atTime, loopStart, device_animation_dot_startAt, progress, state)
      elif device_animation_dot_fireAt > device_animation_dot_startAt && atTime > device_animation_dot_fireAt
        fire_state(eid, atTime, act.dt, device_animation_dot_firePrepareTime, device_animation_dot_firePostTime,
                   device_animation_dot_fireAt, progress, state)
      else
        use_state(atTime, loopStart, device_animation_dot_loopTime, progress, state)

    set_device_state(humanPhysVars, humanDeviceAnimState, humanDeviceAnimProgress, humanDeviceStateVarId, humanDeviceProgressVarId, humanDeviceStates, state, progress)
    set_device_state(phys_vars, device_anim_dot_state, device_anim_dot_progress, device_anim_dot_stateVarId, device_anim_dot_progressVarId, device_anim_dot_states, state, progress)
    if device_anim_dot_isFpvVarId >= 0
      set_var(phys_vars, device_anim_dot_isFpvVarId, isTpsView ? 0.0 : 1.0)

[es (tag=gameClient, track=human_gun_attached, REQUIRE=device_anim_dot_stateVarId)]
def device_anim_unequipped_animchar_update(evt : Event;
                                           human_gun_attached : bool;
                                           var phys_vars : PhysVars;
                                           var animchar : AnimcharBaseComponent;
                                           var anim_phys : AnimatedPhys;
                                           var device_animation_dot_isActive : bool&)
  if !human_gun_attached
    device_animation_dot_isActive = false;
    anim_phys_update(anim_phys, animchar, phys_vars);
    animchar_act(animchar, 0.01, true)
