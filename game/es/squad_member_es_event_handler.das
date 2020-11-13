require ecs
require EnlistedWalkerai

def check_squad_alive_members(squad_eid: EntityId)
  if squad_eid != ecs::INVALID_ENTITY_ID
    setOptional(squad_eid, "squad.isCheckMembersDeffered", true)

[es (on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=walker_agent)]
def squad_member_init_es(evt : Event; squad_member_dot_squad: EntityId)
  if squad_member_dot_squad != ecs::INVALID_ENTITY_ID
    check_squad_alive_members(squad_member_dot_squad)

[es (on_event=EventComponentChanged, track=squad_member_dot_squad, REQUIRE=walker_agent, REQUIRE=isAlive)]
def squad_member_changed_squad_es(evt : Event; squad_member_dot_squad: EntityId)
  if squad_member_dot_squad != ecs::INVALID_ENTITY_ID
    check_squad_alive_members(squad_member_dot_squad)

[es (on_event=EventComponentChanged, track=isAlive, REQUIRE=isAlive)]
def squad_member_check_alive_es(evt : Event; squad_member_dot_squad: EntityId)
  check_squad_alive_members(squad_member_dot_squad)
