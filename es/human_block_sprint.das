require ecs
require Action
require EnlistedHuman
require HumanPhys

[es(no_order)]
def human_block_sprint_es(info : UpdateStageInfoAct;
                          eid : ecs::EntityId;
                          var human_net_phys : HumanActor;
                          human_weap_dot_throwMode : bool;
                          burning_dot_isPuttingOut : bool = false)
  let blocked = human_weap_dot_throwMode || is_action_running(eid) || burning_dot_isPuttingOut
  human_phys_state_set_block_sprint(human_net_phys.phys.currentState, blocked)