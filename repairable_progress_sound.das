require ecs
require ecs.common
require soundHash
require game.es.sound.sound_player

[es (track=repairable_dot_inProgress, tag=sound)]
def repairable_progress_sound_es(evt : Event;
                                 repairable_dot_inProgress : bool;
                                 var sound_group : IPoint3List;
                                 sound_paths : ecs::Object;
                                 sound_descs : ecs::Object;
                                 is_watched_sound : bool;
                                 transform : float3x4)
  if repairable_dot_inProgress
    sound_player::play_sound("repair", sound_hash("repair"), sound_paths, sound_descs, 0l/*sound_allTags*/, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("repair"))

[es (track=extinguishable_dot_inProgress, tag=sound)]
def extinguishable_progress_sound_es(evt : Event;
                                     extinguishable_dot_inProgress : bool;
                                     var sound_group : IPoint3List;
                                     sound_paths : ecs::Object;
                                     sound_descs : ecs::Object;
                                     is_watched_sound : bool;
                                     transform : float3x4)
  if extinguishable_dot_inProgress
    sound_player::play_sound("extinguish", sound_hash("repair"), sound_paths, sound_descs, 0l/*sound_allTags*/, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("repair"))
