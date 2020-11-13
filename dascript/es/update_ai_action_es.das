require ecs

[es (tag=server, no_order)]
def update_ai_action_es(act : ecs::UpdateStageInfoAct; walker_agent_dot_serverAiAction : int;
                        var walker_agent_dot_nextAiActionUpdate : float&;
                        var walker_agent_dot_currentAiAction : int&;
                        walker_agent_dot_updateAiActionEvery : float = 1.0)
  if act.curTime >= walker_agent_dot_nextAiActionUpdate
    walker_agent_dot_currentAiAction = walker_agent_dot_serverAiAction
    walker_agent_dot_nextAiActionUpdate = act.curTime + walker_agent_dot_updateAiActionEvery
