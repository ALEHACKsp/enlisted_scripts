require ecs
require EnlistedHuman
require math

[es]
def human_in_spawn_stamina_es(ecs : UpdateStageInfoAct; var human_net_phys : HumanActor; in_spawn : bool)
  if !in_spawn
    return
  human_net_phys.phys.currentState.staminaDrainMult = 0.0

[es]
def human_in_spawn_speed_es(ecs : UpdateStageInfoAct; var human_net_phys : HumanActor; in_spawn : bool)
  if !in_spawn
    return
  // TODO: move to entity_mods and apply with proper multiplier (setup in entity)
  human_net_phys.phys.currentState.moveSpeedMult = min(human_net_phys.phys.currentState.moveSpeedMult * 1.5, 1e+10)