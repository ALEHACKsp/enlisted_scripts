require ecs
require soundHash
require game.es.sound.sound_player

[es (track=burning_dot_isBurning, tag=sound, REQUIRE=humanSound)]
def human_burning_sound_toggle_es(evt:Event;
                                  burning_dot_isBurning : bool;
                                  sound_allTags : int64;
                                  var sound_group : IPoint3List;
                                  sound_paths : ecs::Object;
                                  sound_descs : ecs::Object;
                                  is_watched_sound : bool;
                                  transform : float3x4)
  if burning_dot_isBurning
    sound_player::play_sound("burning", sound_hash("burning"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("burning"))

[es (track=burning_dot_isPuttingOut, tag=sound, REQUIRE=humanSound)]
def human_burning_putting_out_sound_toggle_es(evt:Event;
                                              burning_dot_isPuttingOut : bool;
                                              sound_allTags : int64;
                                              var sound_group : IPoint3List;
                                              sound_paths : ecs::Object;
                                              sound_descs : ecs::Object;
                                              is_watched_sound : bool;
                                              transform : float3x4)
  if burning_dot_isPuttingOut
    sound_player::play_sound("burningPuttingOut", sound_hash("burningPuttingOut"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("burningPuttingOut"))
