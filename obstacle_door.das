require ecs
require game.es.events
require pathfinder
require DagorRandom
require DagorMath
require CollRes
require RendInst

def obstacle_door_update(var obstacle_dot_handle : int&;
                         transform : float3x4;
                         rendinst_axis_rotation_dot_targetAngle : float;
                         door_operations_dot_closedAngle : float;
                         ri_extra : RiExtraComponent;
                         obstacle_dot_padding)
  let isDoorClosed = rendinst_axis_rotation_dot_targetAngle == door_operations_dot_closedAngle
  if isDoorClosed
    tilecache_obstacle_remove(obstacle_dot_handle)
    obstacle_dot_handle = 0
    return

  if obstacle_dot_handle != 0
    return

  let riType = handle_to_ri_type(ri_extra.handle)
  let doorCollres = get_ri_gen_extra_collres(int(riType))
  if doorCollres != null
    var box = doorCollres.vFullBBox
    box.bmin.y -= obstacle_dot_padding
    box.bmax.y += obstacle_dot_padding
    obstacle_dot_handle = tilecache_obstacle_add(transform, BBox3(box))

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventLevelLoaded)]
def obstacle_door_created_es(evt : Event;
                             var obstacle_dot_handle : int&;
                             transform : float3x4;
                             rendinst_axis_rotation_dot_targetAngle : float;
                             door_operations_dot_closedAngle : float;
                             ri_extra : RiExtraComponent;
                             isDoor : bool = false;
                             obstacle_dot_padding : float = 0.0f)
  if !isDoor
    return
  obstacle_door_update(obstacle_dot_handle, transform,
    rendinst_axis_rotation_dot_targetAngle, door_operations_dot_closedAngle,
    ri_extra, obstacle_dot_padding)

// Only update state once rotation is done (i.e. rendinst_axis_rotation.enabled is removed)
[es (tag=server, on_event=EventComponentsDisappear, REQUIRE=rendinst_axis_rotation_dot_enabled)]
def obstacle_door_state_es(evt : Event;
                           var obstacle_dot_handle : int&;
                           transform : float3x4;
                           rendinst_axis_rotation_dot_targetAngle : float;
                           door_operations_dot_closedAngle : float;
                           ri_extra : RiExtraComponent;
                           isDoor : bool = false;
                           obstacle_dot_padding : float = 0.0f)
  if !isDoor
    return
  obstacle_door_update(obstacle_dot_handle, transform,
    rendinst_axis_rotation_dot_targetAngle, door_operations_dot_closedAngle,
    ri_extra, obstacle_dot_padding)
