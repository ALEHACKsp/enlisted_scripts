require ecs

[es (track=isAlive, REQUIRE=human)]
def disable_attachhes_animchar_update_on_die(evt: Event; attaches_list: ecs::EidList; isAlive: bool)
  if isAlive
    return
  for eid in attaches_list
    ecs::query(eid) <| $ [es (REQUIRE=animchar_dot_noUpdateOnDeath)] (var animchar_dot_updatable : bool&)
      animchar_dot_updatable = isAlive