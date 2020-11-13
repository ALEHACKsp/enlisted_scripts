require ecs

[es (tag=server, no_order)]
def squad_cleanup_es(act : ecs::UpdateStageInfoAct; eid : ecs::EntityId;
                     squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int;
                     var squad_dot_hasMembersBefore : bool&)
  if squad_dot_numAliveMembers > 0
    squad_dot_hasMembersBefore = true
  elif squad_dot_hasMembersBefore
    if !doesEntityExist(squad_dot_leader)
      destroyEntity(eid)
