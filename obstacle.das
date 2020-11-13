require ecs
require game.es.events
require pathfinder

[es (tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def obstacle_destroyed_es(evt : Event; var obstacle_dot_handle : int&)
  tilecache_obstacle_remove(obstacle_dot_handle)
  obstacle_dot_handle = 0
