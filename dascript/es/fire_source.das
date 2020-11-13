require ecs
require DagorSystem
require app
require math
require DagorMath
require DagorMathUtils
require vehicle
require AnimV20

def collect_affected_optics(pos : float3;
                            eid : ecs::EntityId;
                            cylinder_radius : float;
                            cylinder_height : float;
                            cylinder_bottom_offset : float;
                            var out_affected_optics : ecs::IntList)
  query(eid) <| $ [es] (animchar : AnimcharBaseComponent;
                        vehicle_seats_camera_nodes_dot_indices : IntList;
                        vehicle_seats_owners : VehicleSeatsOwners;
                        vehicle_seats_limited_visibility : ecs::IntList)
    let visibilityLength = length(vehicle_seats_limited_visibility)
    if visibilityLength == 0
      return
    let owners & = vehicle_seats_owners.data
    for seatNo in range(0, min(visibilityLength, length(owners)))
      let node = vehicle_seats_camera_nodes_dot_indices[seatNo]

      var wtm : float3x4
      animchar_get_node_wtm(animchar, node, wtm)
      let opticPos = wtm[3]
      let opticDir = normalize(wtm[0]) * cylinder_radius

      let p0 = opticPos
      let p1 = opticPos+opticDir
      let cylinder_p0 = pos + float3(0.0, cylinder_bottom_offset, 0.0)
      let cylinder_p1 = pos + float3(0.0, cylinder_height, 0.0)
      if test_segment_cylinder_intersection(p0, p1, cylinder_p0, cylinder_p1, cylinder_radius)
        push_back(out_affected_optics, seatNo)

def calc_fire_size(time : float; start_time : float; spread_time : float; full_force_time : float; fade_time : float; scale : float) : float
  let maxSpreadTime = start_time + spread_time
  if time < maxSpreadTime
    return scale * cvt(time, start_time, maxSpreadTime, 0.0, 1.0)
  let fadeStartTime = maxSpreadTime + full_force_time
  if time < fadeStartTime
    return scale
  return scale * cvt(time, fadeStartTime, fadeStartTime + fade_time, 1.0, 0.0)

def change_visibility(node_attached_dot_entity : ecs::EntityId;
                      fire_affected_optics : ecs::IntList;
                      visibility_change : int)
  query(node_attached_dot_entity) <| $ [es] (var vehicle_seats_limited_visibility : ecs::IntList)
    for affectedIndex in fire_affected_optics
      if affectedIndex >= length(vehicle_seats_limited_visibility)
        logerr("fire_affected_optics has invalid seatIndex: {affectedIndex}. Total seats: {length(vehicle_seats_limited_visibility)}")
      else
        vehicle_seats_limited_visibility[affectedIndex] += visibility_change


[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def fire_source_init_start_time(evt : Event; var fire_source_dot_startTime : float&)
  fire_source_dot_startTime = get_sync_time()

[es (tag=server, on_event=EventComponentsAppear)]
def fire_source_init_affected_optics(evt : Event; transform : float3x4;
                                     node_attached_dot_entity : ecs::EntityId;
                                     var fire_affected_optics : ecs::IntList;
                                     visibilityRestrictionRadius : float = 0.5;
                                     visibilityRestrictionHeight : float = 1.0;
                                     visibilityRestrictionBottomOffset : float = -0.35)
  collect_affected_optics(transform[3], node_attached_dot_entity,
      visibilityRestrictionRadius, visibilityRestrictionHeight, visibilityRestrictionBottomOffset, fire_affected_optics)
  change_visibility(node_attached_dot_entity, fire_affected_optics, +1)

[es (tag=server, on_event=EventEntityDestroyed)]
def fire_source_destroyed_restore_affected_optics(evt : Event;
                                                  node_attached_dot_entity : ecs::EntityId;
                                                  fire_affected_optics : ecs::IntList)
  change_visibility(node_attached_dot_entity, fire_affected_optics, -1)

[es (tag=server, no_order)]
def fire_source_progress(info: UpdateStageInfoAct;
                          eid : ecs::EntityId;
                          var sphere_zone_dot_radius : float&;
                          fire_source_dot_startTime : float;
                          fire_source_dot_fullForceTime : float;
                          fire_source_dot_spreadTime : float = 0.0;
                          fire_source_dot_fadeTime : float = 0.0;
                          fire_source_dot_scale : float = 1.0)
  let duration = fire_source_dot_spreadTime + fire_source_dot_fullForceTime + fire_source_dot_fadeTime
  let time = info.curTime
  if time > fire_source_dot_startTime + duration
    destroyEntity(eid)
  else
    sphere_zone_dot_radius = calc_fire_size(time, fire_source_dot_startTime,
        fire_source_dot_spreadTime, fire_source_dot_fullForceTime, fire_source_dot_fadeTime, fire_source_dot_scale)

[es (tag=render, no_order)]
def fire_source_effect(info: UpdateStageInfoAct;
                       var effect_dot_scale : float&;
                       fire_source_dot_startTime : float;
                       fire_source_dot_effectScale : float;
                       fire_source_dot_fullForceTime : float;
                       fire_source_dot_spreadTime : float = 0.0;
                       fire_source_dot_fadeTime : float = 0.0;
                       fire_source_dot_scale : float = 1.0;
                       fire_source_dot_effectMinScale : float = 0.0)
  let zone_size = calc_fire_size(info.curTime, fire_source_dot_startTime,
      fire_source_dot_spreadTime, fire_source_dot_fullForceTime, fire_source_dot_fadeTime, fire_source_dot_scale)
  effect_dot_scale = max(fire_source_dot_effectMinScale, zone_size * fire_source_dot_effectScale)
