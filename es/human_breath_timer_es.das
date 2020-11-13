require ecs
require math
require dm
require AnimV20
require HumanPhys
require HumanBreath
require EnlistedHuman

def update_breath(dt : float;
                  underwater : bool;
                  eid : EntityId;
                  var human_breath_dot_timer : float&;
                  var human_breath_dot_asphyxiationTimer : float&;
                  transform : float3x4;
                  human_breath_dot_maxHoldBreathTime : float;
                  human_breath_dot_recoverBreathMult : float;
                  human_breath_dot_damagePerTick : float;
                  human_breath_dot_damageTick : float)
  if underwater
    human_breath_dot_timer = min(human_breath_dot_timer + dt, human_breath_dot_maxHoldBreathTime)
  else
    human_breath_dot_timer = max(human_breath_dot_timer - dt * human_breath_dot_recoverBreathMult, 0.0)
  if human_breath_dot_timer >= human_breath_dot_maxHoldBreathTime
    human_breath_dot_asphyxiationTimer = human_breath_dot_asphyxiationTimer + dt
    if human_breath_dot_asphyxiationTimer > human_breath_dot_damageTick
      human_breath_dot_asphyxiationTimer = human_breath_dot_asphyxiationTimer - human_breath_dot_damageTick
      let dd = DamageDesc(DamageType DM_HOLD_BREATH, human_breath_dot_damagePerTick, transform[3], float3(0.0,-1.0,0.0))
      damage_entity(eid, eid, dd)

[es]
def human_breath_timer_es(act : UpdateStageInfoAct;
                          eid : EntityId;
                          isAlive : bool;
                          animchar : AnimcharBaseComponent;
                          breath_node : BreathNode;
                          human_net_phys : HumanActor;
                          var human_breath_dot_timer : float&;
                          var human_breath_dot_asphyxiationTimer : float&;
                          human_breath_dot_maxHoldBreathTime : float;
                          transform : float3x4;
                          updatable : bool;
                          human_breath_dot_recoverBreathMult : float = 2.0;
                          human_breath_dot_damagePerTick : float = 2.0;
                          human_breath_dot_damageTick : float = 1.0)
  if !isAlive
    return
  var isUnderwater = check_node_underwater(breath_node, animchar, act.curTime)
  if updatable && human_net_phys.phys.currentState.standState == HUStandState ESS_SWIM
    isUnderwater = false
  update_breath(act.dt, isUnderwater, eid, human_breath_dot_timer, human_breath_dot_asphyxiationTimer,
                transform, human_breath_dot_maxHoldBreathTime, human_breath_dot_recoverBreathMult,
                human_breath_dot_damagePerTick, human_breath_dot_damageTick)
