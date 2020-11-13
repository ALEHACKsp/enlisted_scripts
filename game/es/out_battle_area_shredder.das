require ecs
require game.utils.team
require game.es.battle_area_common
require zones

def check_shreddable()
  query() <| $[es (REQUIRE=shredOutsideBattleArea)] (eid : EntityId; transform : float3x4; team = int(TEAM_UNASSIGNED))
    let pos = transform[3]
    if !has_active_human_battle_area_at(pos, team)
      destroyEntity(eid)

[es (tag=server, REQUIRE=(battle_area,humanTriggerable), on_event=EventEntityDestroyed)]
def out_battle_area_shredder_destroyed_check(evt : Event)
  check_shreddable()

[es (tag=server, track=active, REQUIRE=(battle_area,humanTriggerable))]
def out_battle_area_shredder_deactivate_check(evt : Event; active : bool)
  if !active
    check_shreddable()
