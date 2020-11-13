require ecs
require game.es.app_common
require DagorConsole

[console_cmd(name="suicide_penalty.disable")]
def suicide_penalty_enable(disable: bool = true)
  query() <| $[es (REQUIRE=player)](eid: EntityId)
    if disable
      removeSubTemplate(eid, "suicide_penalty")
    else
      addSubTemplate(eid, "suicide_penalty")

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=player)]
def suicide_penalty_enable(evt: Event; eid: EntityId)
  addSubTemplate(eid, "suicide_penalty")