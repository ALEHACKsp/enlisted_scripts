require ecs
require Action

[es(no_order)]
def track_active_action_es(
    info : UpdateStageInfoAct;
    eid : EntityId;
    var action_dot_running : bool&)

  action_dot_running = is_action_running(eid)