require ecs
require game.es.events
require pathfinder
require DagorRandom
require DagorMath

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventLevelLoaded)]
def obstacle_fire_created_es(evt : Event;
                             var obstacle_dot_handle : int&;
                             transform : float3x4;
                             sphere_zone_dot_radius : float;
                             fire_source_dot_scale : float = 0.0f;
                             obstacle_dot_padding : float = 0.0f)
  if obstacle_dot_handle != 0
    return
  var radius = sphere_zone_dot_radius
  if fire_source_dot_scale > 0.0f
    radius = fire_source_dot_scale
  radius += obstacle_dot_padding
  let ext = float3(radius, radius, radius)
  var tm : float3x4
  rotyTM(rnd_float(0.0f, PI * 2.0f), tm)
  obstacle_dot_handle = tilecache_obstacle_add(transform * tm, BBox3(-ext, ext));
