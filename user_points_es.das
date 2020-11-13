require ecs
require game.es.events
require game.utils.team

def destroy_point(eid : ecs::EntityId; target : ecs::EntityId)
  destroyEntity(eid)
  let countPtr = get_int(target, "countUserMark")
  if countPtr == null
    return
  let count = deref(countPtr)
  if count < 1
    removeSubTemplate(target, "user_point_entities_tracker")
  else
    set(target, "countUserMark", count - 1)

[es (tag = server, no_order)]
def map_user_point_timer_es(info:UpdateStageInfoAct;
                            eid : ecs::EntityId;
                            timer_dot_destroy : float;
                            target:ecs::EntityId = INVALID_ENTITY_ID)
  if info.curTime > timer_dot_destroy
    destroy_point(eid, target)


[es (tag = server, on_event=CmdDeleteMapUserPoint)]
def destroy_map_user_point_es(evt : Event;
                              eid : ecs::EntityId;
                              target: EntityId = INVALID_ENTITY_ID)
  destroy_point(eid, target)


[es (tag = server)]
def clear_all_map_user_point_es(evt : CmdClearAllAttachedUserPoint;
                                eid : ecs::EntityId;
                                target : ecs::EntityId;
                                team : int)
  if is_teams_friendly(team, evt.team)
    if target == evt.target
      destroy_point(eid, target)
