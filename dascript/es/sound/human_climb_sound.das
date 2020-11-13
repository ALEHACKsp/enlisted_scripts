require ecs
require ecs.common
require soundHash
require game.es.sound.sound_player

[es (track=human_net_phys_dot_isClimbing, tag=sound, REQUIRE=humanSound)]
def human_climb_sound_es(evt : Event;
                         human_net_phys_dot_isClimbing : bool;
                         sound_allTags : int64;
                         var sound_group : IPoint3List;
                         sound_paths : ecs::Object;
                         sound_descs : ecs::Object;
                         is_watched_sound : bool;
                         transform : float3x4)
  if human_net_phys_dot_isClimbing
    sound_player::play_sound("climb", sound_hash(""), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
