require ecs
require zones

[generic]
def is_point_in_zone(pos : float3; zone_eid : ecs::EntityId) : bool
  return is_point_in_zone(pos, zone_eid, 1.0)
