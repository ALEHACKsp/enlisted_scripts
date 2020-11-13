require ecs
require soundHash
require game.es.sound.sound_player

[es (tag=sound, after=human_sound_es)]
def human_fall_sound_es(info:UpdateStageInfoAct;
                        sound_allTags : int64;
                        sound_paths : ecs::Object;
                        sound_descs : ecs::Object;
                        var sound_group : IPoint3List;
                        is_watched_sound : bool;
                        human_net_phys_dot_isUnderwater : bool;
                        human_net_phys_dot_deltaVelIgnoreAmount : float;
                        human_net_phys_dot_velocity : float3 const&;
                        human_fall_sound_dot_threshold : float;
                        human_fall_sound_dot_enabled : bool = true;
                        human_fall_sound_dot_cryInterval : float;
                        var human_fall_sound_dot_cryTime : float &;
                        var human_fall_sound_dot_isFalling : bool &;
                        transform : float3x4;
                        isAlive : bool;
                        isDowned : bool;
                        human_spawn_sound_dot_inSpawn : bool = false)

  let wasFalling = human_fall_sound_dot_isFalling
  human_fall_sound_dot_isFalling = (human_fall_sound_dot_enabled &&
                                    human_net_phys_dot_velocity.y < -human_fall_sound_dot_threshold &&
                                    !human_spawn_sound_dot_inSpawn &&
                                    !human_net_phys_dot_isUnderwater &&
                                    human_net_phys_dot_deltaVelIgnoreAmount <= 0.0)

  if human_fall_sound_dot_isFalling && isAlive && !isDowned
    if info.curTime >= human_fall_sound_dot_cryTime + human_fall_sound_dot_cryInterval
      human_fall_sound_dot_cryTime = info.curTime
      sound_player::play_sound("fall", sound_hash("fall"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  elif wasFalling
    sound_player::abandon_sound(sound_group, sound_hash("fall"))
