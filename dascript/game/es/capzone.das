require ecs
require pathfinder
require DagorSystem
require game.es.events

[private]
def init_nearest_pos(eid : EntityId; transform : float3x4; sphere_zone_dot_radius : float;
                    var capzone_dot_hasNearestNavmeshPos : bool&; var capzone_dot_nearestNavmeshPos : float3&)
  capzone_dot_nearestNavmeshPos = transform[3]
  let radius = sphere_zone_dot_radius > 0.0 ? sphere_zone_dot_radius : length(transform[0])
  capzone_dot_hasNearestNavmeshPos = project_to_nearest_navmesh_point(capzone_dot_nearestNavmeshPos, radius)
  if !capzone_dot_hasNearestNavmeshPos
    logerr("can't find nearest navmesh position for capzone {eid} <{getEntityTemplateName(eid)}> at {transform[3]}")

[es(tag=server)]
def capzone_init_nearest_navmesh_point(evt : EventEntityCreated;
                                      eid : EntityId; transform : float3x4; sphere_zone_dot_radius : float = 0.0;
                                      var capzone_dot_hasNearestNavmeshPos : bool&;
                                      var capzone_dot_nearestNavmeshPos : float3&)
  if pathfinder_is_loaded()
    init_nearest_pos(eid, transform, sphere_zone_dot_radius, capzone_dot_hasNearestNavmeshPos, capzone_dot_nearestNavmeshPos)

[es (tag=server, on_event=EventLevelLoaded)]
def capzone_init_all_nearest_navmesh_points(evt : Event)
  query() <| $[es](eid : EntityId; transform : float3x4; sphere_zone_dot_radius : float = 0.0;
                  var capzone_dot_hasNearestNavmeshPos : bool&;
                  var capzone_dot_nearestNavmeshPos : float3&)
    init_nearest_pos(eid, transform, sphere_zone_dot_radius, capzone_dot_hasNearestNavmeshPos, capzone_dot_nearestNavmeshPos)
