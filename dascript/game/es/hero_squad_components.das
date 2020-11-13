require ecs
require DagorSystem
require game.utils.hero

[es (tag=gameClient, on_event=(EventEntityCreated,EventComponentsAppear), REQUIRE=hero, REQUIRE_NOT=heroSquad)]
def init_hero_squad_components(evt : Event; squad_member_dot_squad : EntityId)
  let hero_squad = squad_member_dot_squad
  query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId)
    if squad_member_dot_squad == hero_squad
      addSubTemplate(eid, "human_hero_squad_components")
    else
      removeSubTemplate(eid, "human_hero_squad_components")

[es (tag=gameClient, on_event=(EventEntityCreated,EventComponentsAppear), REQUIRE=watchedByPlr, REQUIRE_NOT=watchedSquad)]
def init_watched_squad_components(evt : Event; squad_member_dot_squad : EntityId)
  let watched_squad = squad_member_dot_squad
  query() <| $ [es] (eid : EntityId; squad_member_dot_squad : EntityId)
    if squad_member_dot_squad == watched_squad
      addSubTemplate(eid, "human_watched_squad_components")
    else
      removeSubTemplate(eid, "human_watched_squad_components")
