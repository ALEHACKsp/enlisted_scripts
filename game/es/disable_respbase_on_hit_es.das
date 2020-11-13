require ecs
require game.es.events
require math
require math.base

[es]
def disable_respbase_on_hit_es(evt: EventOnEntityHit;
                               transform: float3x4;
                               spawn_immunity_dot_initialPos: float3 const&;
                               spawn_immunity_dot_immuneDistance: float;
                               lastRespawnBaseEid: ecs::EntityId)
  if distance_sq(spawn_immunity_dot_initialPos, transform[3]) <= square(spawn_immunity_dot_immuneDistance)
    ecs::query(lastRespawnBaseEid) <| $[es (REQUIRE=temporaryRespawnbase)](var active: bool&)
      active = false
