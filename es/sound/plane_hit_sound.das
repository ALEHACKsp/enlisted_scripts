require ecs
require ecs.common
require game.es.sound.sound_player
require game.es.events
require soundSystem
require soundEvent
require CollRes
require DagorSystem
require DagorMath

def remove_sound(var handles : IntList&; var positions : Point3List&; idx : int)
  soundEvent::abandon(handles[idx])
  erase(handles, idx)
  erase(positions, idx)

def clear_sounds(var handles : IntList&; var positions : Point3List&)
  for handle in handles
    soundEvent::release(handle)
  clear(handles)
  clear(positions)

def convert(v : float; r : float4)
  return cvt(v, r.x, r.y, r.z, r.w)

def on_hit(caliber : float; local_pos : float3;
           event : string;
           sound_paths : ecs::Object;
           sound_descs : ecs::Object;
           is_watched_sound : bool;
           transform : float3x4;
           entity_sound_dot_enabled : bool;
           caliber_to_dist : float4;
           caliber_to_var : float4;
           var handles : IntList&;
           var positions : Point3List&)
  let maxDist = convert(caliber, caliber_to_dist)
  if entity_sound_dot_enabled && (is_watched_sound || length_sq(get_listener_pos() - transform * local_pos) < maxDist * maxDist)
    var handle = sound_player::play_sound(event, sound_paths, sound_descs, 0l/*sound_allTags*/, is_watched_sound, transform * local_pos, false/*is_abandon*/)
    if handle != 0
      soundEvent::set_var(handle, "cal", convert(caliber, caliber_to_var))
      if is_watched_sound
        push_back(handles, handle)
        push_back(positions, local_pos)
      else
        soundEvent::abandon(handle)

[es (tag=sound)]
def plane_hit_sound_on_hit(evt : EventOnHitByProjectile;
                           sound_paths : ecs::Object;
                           sound_descs : ecs::Object;
                           is_watched_sound : bool;
                           transform : float3x4;
                           entity_sound_dot_enabled : bool;
                           plane_hit_sound_dot_caliberToDist : float4;
                           plane_hit_sound_dot_caliberToVar : float4;
                           var plane_hit_sound_dot_handles : IntList&;
                           var plane_hit_sound_dot_positions : Point3List&;
                           plane_hit_sound_dot_canopyNodeIds : IntList?)
  on_hit(evt.caliber, evt.localHitPos,
         (plane_hit_sound_dot_canopyNodeIds != null && find_index(*plane_hit_sound_dot_canopyNodeIds, evt.nodeId) >= 0) ? "hitGlass" : "hit",
         sound_paths,
         sound_descs,
         is_watched_sound,
         transform,
         entity_sound_dot_enabled,
         plane_hit_sound_dot_caliberToDist,
         plane_hit_sound_dot_caliberToVar,
         plane_hit_sound_dot_handles,
         plane_hit_sound_dot_positions)

[es (tag=sound)]
def plane_hit_sound_on_ricochet(evt : EventOnRicochet;
                                sound_paths : ecs::Object;
                                sound_descs : ecs::Object;
                                is_watched_sound : bool;
                                transform : float3x4;
                                entity_sound_dot_enabled : bool;
                                plane_hit_sound_dot_caliberToDist : float4;
                                plane_hit_sound_dot_caliberToVar : float4;
                                var plane_hit_sound_dot_handles : IntList&;
                                var plane_hit_sound_dot_positions : Point3List&)
  on_hit(evt.caliber, evt.localHitPos,
         "ricochet",
         sound_paths,
         sound_descs,
         is_watched_sound,
         transform,
         entity_sound_dot_enabled,
         plane_hit_sound_dot_caliberToDist,
         plane_hit_sound_dot_caliberToVar,
         plane_hit_sound_dot_handles,
         plane_hit_sound_dot_positions)

[es (tag=sound, on_event=EventOnCollisionHit)]
def plane_hit_sound_on_coll_hit(evt : Event;
                                sound_paths : ecs::Object;
                                sound_descs : ecs::Object;
                                is_watched_sound : bool;
                                transform : float3x4;
                                entity_sound_dot_enabled : bool)
  if entity_sound_dot_enabled && is_watched_sound
    sound_player::play_sound("collision", sound_paths, sound_descs, 0l/*sound_allTags*/, is_watched_sound, transform[3])

[es (tag=sound, after=animchar_render_es)]
def plane_hit_sound_update(info:UpdateStageInfoAct;
                           var plane_hit_sound_dot_handles : IntList&;
                           var plane_hit_sound_dot_positions : Point3List&;
                           transform : float3x4)
  if length(plane_hit_sound_dot_handles) != length(plane_hit_sound_dot_positions)
    logerr("plane_hit_sound: lengths of two lists are not equal!")
    clear_sounds(plane_hit_sound_dot_handles, plane_hit_sound_dot_positions)
  var idx:int = length(plane_hit_sound_dot_handles)
  while --idx >= 0
    if soundEvent::is_playing(plane_hit_sound_dot_handles[idx])
      soundEvent::set_pos(plane_hit_sound_dot_handles[idx], transform * plane_hit_sound_dot_positions[idx])
    else
      remove_sound(plane_hit_sound_dot_handles, plane_hit_sound_dot_positions, idx)
  while length(plane_hit_sound_dot_handles) > 16
    remove_sound(plane_hit_sound_dot_handles, plane_hit_sound_dot_positions, 0)

[es (tag=sound)]
def plane_hit_sound_init(evt : EventEntityCreated;
                         eid : EntityId;
                         collres : CollisionResource;
                         plane_hit_sound_dot_canopyNodes : StringList;
                         var plane_hit_sound_dot_canopyNodeIds : IntList&)
  for nodeName in plane_hit_sound_dot_canopyNodes
    let nodeIdx = collres_get_node_index_by_name(collres, string(nodeName))
    if nodeIdx < 0
      logerr("Canopy node {nodeName} was not found in {eid} <{getEntityTemplateName(eid)}>")
    else
      push_back(plane_hit_sound_dot_canopyNodeIds, nodeIdx)

[es (tag=sound)]
def plane_hit_sound_entity_destroy(evt : EventEntityDestroyed;
                                   var plane_hit_sound_dot_handles : IntList&;
                                   var plane_hit_sound_dot_positions : Point3List&)
  clear_sounds(plane_hit_sound_dot_handles, plane_hit_sound_dot_positions)
