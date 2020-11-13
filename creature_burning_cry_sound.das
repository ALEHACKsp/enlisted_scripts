require ecs
require soundHash
require game.es.sound.sound_player

[es (tag=sound, REQUIRE=creatureBurningCrySound, track=burning_dot_isBurning, track=is_watched_sound)]
def creature_burning_cry_sound_es(evt : Event;
                                  sound_paths : ecs::Object;
                                  sound_descs : ecs::Object;
                                  transform : float3x4;
                                  var sound_group : IPoint3List;
                                  burning_dot_isBurning : bool;
                                  isAlive : bool;
                                  isDowned : bool = false;
                                  sound_allTags : int64 = 0l;
                                  is_watched_sound : bool = false;
                                  human_net_phys_dot_isUnderwater : bool = false;
                                  human_net_phys_dot_isHoldBreath : bool = false)
  if burning_dot_isBurning && isAlive && !isDowned && !human_net_phys_dot_isHoldBreath && !human_net_phys_dot_isUnderwater
    sound_player::play_sound("burningCry", sound_hash("burningCry"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("burningCry"))
