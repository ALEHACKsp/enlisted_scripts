require ecs
require ecs.common
require soundHash
require game.es.sound.sound_player
require DagorSystem

[es (track=building_action_dot_target, tag=sound)]
def human_sound_building_action_tag_es(evt : Event;
                                       building_action_dot_target : ecs::EntityId;
                                       sound_tags : ecs::Object;
                                       var human_sound_dot_optionalTags : int64 &)

  let allBuildTags = sound_player::get_tag(sound_tags, "pathTags_build")
  human_sound_dot_optionalTags &= ~allBuildTags

  query(building_action_dot_target) <| $[es](buildingSoundTag : string)
    let tag = sound_player::get_tag(sound_tags, "build_{buildingSoundTag}")
    if (allBuildTags & tag) != 0l
      human_sound_dot_optionalTags |= tag
    else
      logerr("there is no buildingSoundTag '{buildingSoundTag}' in human_sound 'build' path")
