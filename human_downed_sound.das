require ecs
require soundHash
require game.es.sound.sound_player

[es (tag=sound, REQUIRE=humanSound, track=(is_watched_sound,isDowned,isAlive))]
def human_downed_sound_es(evt:Event;
                          sound_paths : ecs::Object;
                          sound_descs : ecs::Object;
                          sound_allTags : int64;
                          transform : float3x4;
                          var sound_group : IPoint3List;
                          is_watched_sound : bool;
                          isDowned : bool;
                          isAlive : bool)
  sound_player::abandon_sound(sound_group, sound_hash("downed"))
  if isDowned && isAlive
    sound_player::abandon_all_sounds(sound_group)
    sound_player::play_sound("downed", sound_hash("downed"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
