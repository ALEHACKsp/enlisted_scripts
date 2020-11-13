require ecs
require ecs.common
require EnlistedHuman
require HumanPhys
require player
require game.es.events

def reset_human_aim_zoom(var human_net_phys : HumanActor; var camera_dot_magnification : float&)
  human_net_phys.phys.currentState.aimPosition = 0.f
  human_net_phys.phys.currentState.zoomPosition = 0.f
  human_net_phys.phys.previousState.aimPosition = 0.f
  human_net_phys.phys.previousState.zoomPosition = 0.f
  camera_dot_magnification = 1.f

[es(before=after_net_phys_sync, after=before_net_phys_sync)]
def human_weap_phys_es(
  info : UpdateStageInfoAct;
  human_weap_dot_reloadAtTime : float;
  human_weap_dot_weapModActivateStartTime : float;
  boltActionProgress : float;
  isGunManualLoadMode : bool;
  isInVehicle : bool;
  isPassenger : bool;
  var human_net_phys : HumanActor;
  human_dot_lockZoom = false;
  human_attached_gun_dot_isAttached = false;
  isDowned = false;
  action_dot_running = false)

  var ct & = human_net_phys.phys.currentState
  let reloading = (info.curTime <= human_weap_dot_reloadAtTime) || (human_weap_dot_weapModActivateStartTime > 0.0f)
  var standState = ct.standState
  let isCrawling = ct.moveState != HUMoveState EMS_STAND && ct.isCrawl
  let isShootingStandState = standState == HUStandState ESS_STAND || standState == HUStandState ESS_CROUCH || standState == HUStandState ESS_CRAWL
  let isBoltActionInProgress = isGunManualLoadMode ? boltActionProgress > 0.f && boltActionProgress < 1.f : false

  human_phys_state_set_can_aim(ct,
    (!reloading || human_attached_gun_dot_isAttached) &&
    (ct.weapEquipState.curState == HUWeaponEquipState EES_EQUIPED) &&
    !isBoltActionInProgress &&
    !isDowned && (!isInVehicle || isPassenger) && !human_dot_lockZoom && !isCrawling && isShootingStandState)

  human_phys_state_set_can_zoom(ct,
    (!reloading || human_attached_gun_dot_isAttached) &&
    !isDowned && (!isInVehicle || isPassenger) && !human_dot_lockZoom
    && !isBoltActionInProgress
    && !action_dot_running && isShootingStandState)

[es(track=human_anim_dot_vehicleSelected, REQUIRE=human_anim_dot_vehicleSelected)]
def human_weap_zoom_reset_es_event_handler(evt : Event; var human_net_phys : HumanActor; var camera_dot_magnification : float&)
  reset_human_aim_zoom(human_net_phys, camera_dot_magnification)

[es(track=human_dot_lockZoom, REQUIRE=human_dot_lockZoom)]
def human_weap_lock_zoom_reset_es_event_handler(evt : Event; var human_net_phys : HumanActor; var camera_dot_magnification : float&)
  reset_human_aim_zoom(human_net_phys, camera_dot_magnification)

[es(on_event=EventEntityDowned)]
def downed_human_reset_zoom_es_event_handler(evt : Event; var human_net_phys : HumanActor; var camera_dot_magnification : float&)
  reset_human_aim_zoom(human_net_phys, camera_dot_magnification)
