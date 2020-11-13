require ecs
require EnlistedHuman
require math
require DagorMath

[es]
def human_acceleration_reset_es(info: UpdateStageInfoAct;
                                var human_net_phys: HumanActor)
  human_net_phys.phys.currentState.accelerationMult = 1.f

[es]
def human_jump_speed_reset_es(info: UpdateStageInfoAct;
                              var human_net_phys: HumanActor)
  human_net_phys.phys.currentState.jumpSpeedMult = 1.f

[es]
def human_move_speed_reset_es(info: UpdateStageInfoAct;
                              var human_net_phys: HumanActor)
  human_net_phys.phys.currentState.moveSpeedMult = 1.f

[es]
def human_weight_influence_es(info: UpdateStageInfoAct;
                              var human_net_phys: HumanActor;
                              human_inventory_dot_currentWeight: float;
                              human_weight_influence_dot_minWeight: float = 4.f;
                              human_weight_influence_dot_maxWeight: float  = 15.f;
                              human_weight_influence_dot_maxWeightAccelerationMult: float = 0.5f;
                              human_weight_influence_dot_maxWeightJumpMult: float = 0.5f;
                              human_weight_influence_dot_maxWeightSpeedMult: float = 1.f;
                              entity_mods_dot_weightRunSpeedMult: float = 1.f)
  let curLerpFactor = cvt(human_inventory_dot_currentWeight * entity_mods_dot_weightRunSpeedMult,
                              human_weight_influence_dot_minWeight, human_weight_influence_dot_maxWeight,
                              0.f, 1.f)
  human_net_phys.phys.currentState.accelerationMult *= lerp(1.f, human_weight_influence_dot_maxWeightAccelerationMult, curLerpFactor)
  human_net_phys.phys.currentState.jumpSpeedMult *= lerp(1.f, human_weight_influence_dot_maxWeightJumpMult, curLerpFactor)
  human_net_phys.phys.currentState.moveSpeedMult *= lerp(1.f, human_weight_influence_dot_maxWeightSpeedMult, curLerpFactor)