require ecs
require soundHash
require game.es.sound.sound_player

[es (tag=sound, REQUIRE=concussionSoundSuppression, on_event=(EventEntityCreated, EventComponentsAppear))]
def concussion_sound_create(evt : Event; game_effect_dot_attachedTo : EntityId)
  query(game_effect_dot_attachedTo) <| $ [es] (isAlive : bool;
                                               sound_paths : ecs::Object;
                                               sound_descs : ecs::Object;
                                               sound_allTags : int64;
                                               is_watched_sound : bool;
                                               isDowned : bool;
                                               transform : float3x4;
                                               var sound_group : IPoint3List)
    if is_watched_sound && isAlive && !isDowned
      sound_player::play_sound("concussed", sound_hash("concussed"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)

[es (tag=sound, REQUIRE=concussionSoundSuppression, on_event=EventEntityDestroyed)]
def concussion_sound_remove(evt : Event; game_effect_dot_attachedTo : EntityId; concussion_dot_replaced : bool)
  if !concussion_dot_replaced
    query(game_effect_dot_attachedTo) <| $ [es] (var sound_group : IPoint3List)
      sound_player::abandon_sound(sound_group, sound_hash("concussed"))

def is_concussed(eid : EntityId)
  return find_query() <| $ [es (REQUIRE=concussionSoundSuppression)] (game_effect_dot_attachedTo : EntityId)
    return game_effect_dot_attachedTo == eid

[es (tag=sound, track=(is_watched_sound,isAlive,isDowned), REQUIRE=humanSound)]
def concussion_sound_track_es(evt : Event;
                              eid : EntityId;
                              sound_paths : ecs::Object;
                              sound_descs : ecs::Object;
                              sound_allTags : int64;
                              is_watched_sound : bool;
                              isAlive : bool;
                              isDowned : bool;
                              transform : float3x4;
                              var sound_group : IPoint3List)
  sound_player::abandon_sound(sound_group, sound_hash("concussed"))
  if is_watched_sound && isAlive && !isDowned && is_concussed(eid)
    sound_player::play_sound("concussed", sound_hash("concussed"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
