require ecs
require soundHash
require game.es.sound.sound_player
require HumanPhys

[es (tag=sound, track=human_net_phys_dot_curMoveState, REQUIRE=(creatureMoveStateSound,humanSound))]
def creature_move_state_sound_es(evt : Event;
                                 human_net_phys_dot_curMoveState : int;
                                 sound_allTags : int64;
                                 var sound_group : IPoint3List;
                                 sound_paths : ecs::Object;
                                 sound_descs : ecs::Object;
                                 is_watched_sound : bool;
                                 transform : float3x4;
                                 isAlive : bool;
                                 isDowned : bool)
  if human_net_phys_dot_curMoveState == int(HUMoveState EMS_SPRINT) && isAlive
    if !sound_player::has_sound(sound_group, sound_hash("sprintState"))
      sound_player::play_sound("sprintState", sound_hash("sprintState"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("sprintState"))

  if human_net_phys_dot_curMoveState <= int(HUMoveState EMS_WALK) && isAlive && !isDowned
    if !sound_player::has_sound(sound_group, sound_hash("idleState"))
      sound_player::play_sound("idleState", sound_hash("idleState"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  else
    sound_player::abandon_sound(sound_group, sound_hash("idleState"))
