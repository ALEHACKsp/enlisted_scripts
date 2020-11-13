require ecs
require walkerai
require HumanPhys
require math
require game.es.events

[es(tag=server, no_order)]
def ai_target_update_last_actions(act:UpdateStageInfoAct; human_weap_dot_lastShotAtTime : float; var ai_target:Target&)
  ai_target.lastShootTimer = act.curTime - human_weap_dot_lastShotAtTime
  ai_target.lastKillTimer += act.dt

[es (tag=server, no_order)]
def ai_target_track_last_kill(evt:EventAnyEntityDied; eid : EntityId; var ai_target:Target&)
  if eid == evt.offender
    ai_target.lastKillTimer = 0.
    ai_target.lastKillGroupId = int(uint(evt.victimSquad))

[es(tag=server, no_order)]
def ai_target_noise_level(act:UpdateStageInfoAct; var ai_target : Target; human_anim_dot_vehicleSelected : EntityId; human_net_phys_dot_curMoveState : int)
  ai_target.useVehicle = uint(human_anim_dot_vehicleSelected)
  ai_target.noiseLevel = 0f
  if human_anim_dot_vehicleSelected != INVALID_ENTITY_ID
    ai_target.noiseLevel = length_sq(get_Point3(human_anim_dot_vehicleSelected, "net_phys.currentStateVelocity") ?? float3()) > 0.1f ? 1f : 0.5
  elif human_net_phys_dot_curMoveState == int(HUMoveState EMS_SPRINT)
    ai_target.noiseLevel = 0.5

[es(tag=server, no_order)]
def ai_target_phys_velocity(act:UpdateStageInfoAct; net_phys_dot_currentStateVelocity: float3; var ai_target : Target)
  ai_target.velocity = net_phys_dot_currentStateVelocity

[es(tag=server, no_order)]
def ai_target_human_velocity(act:UpdateStageInfoAct; human_net_phys_dot_velocity : float3; human_anim_dot_vehicleSelected : EntityId; var ai_target : Target)
  ai_target.velocity = get_Point3(human_anim_dot_vehicleSelected, "net_phys.currentStateVelocity") ?? human_net_phys_dot_velocity
