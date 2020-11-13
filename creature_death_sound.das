require ecs
require soundHash
require game.es.sound.sound_player

[es (tag=sound, on_event=EventEntityDied, REQUIRE=creatureDeathSound)]
def creature_death_sound_es(evt:Event;
                            sound_paths : ecs::Object;
                            sound_descs : ecs::Object;
                            var sound_group : IPoint3List;
                            transform : float3x4;
                            sound_allTags : int64 = 0l;
                            is_watched_sound : bool = false)
  sound_player::release_all_sounds(sound_group)
  sound_player::play_sound("death", sound_hash(""), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
