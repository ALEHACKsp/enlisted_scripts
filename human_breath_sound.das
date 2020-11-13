require ecs
require HumanPhys
require soundHash
require game.es.sound.sound_player
require soundEvent
require math

[es (track=human_net_phys_dot_isHoldBreath, tag=sound, REQUIRE=humanSound)]
def human_hold_breath_sound_es(evt:Event;
                               human_net_phys_dot_isHoldBreath : bool;
                               human_net_phys_dot_isUnderwater : bool;
                               sound_allTags : int64;
                               var sound_group : IPoint3List;
                               sound_paths : ecs::Object;
                               sound_descs : ecs::Object;
                               is_watched_sound : bool;
                               transform : float3x4;
                               isAlive : bool)
  if human_net_phys_dot_isUnderwater || !isAlive
    return
  let desc = human_net_phys_dot_isHoldBreath ? "holdBreathStart" : "holdBreathEnd"
  sound_player::play_sound(desc, sound_hash("breath"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)


[es (track=human_net_phys_dot_isUnderwater, tag=sound, REQUIRE=humanSound)]
def human_underwater_sound_toggle_es(evt:Event;
                                     human_net_phys_dot_isUnderwater : bool;
                                     sound_allTags : int64;
                                     var sound_group : IPoint3List;
                                     sound_paths : ecs::Object;
                                     sound_descs : ecs::Object;
                                     human_breath_dot_timer : float;
                                     human_breath_dot_maxHoldBreathTime : float;
                                     is_watched_sound : bool;
                                     transform : float3x4;
                                     isAlive : bool)
  if !is_watched_sound || !isAlive
    return
  if human_net_phys_dot_isUnderwater
    sound_player::play_sound("underwaterIn", sound_hash(""), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
  else
    let handle = sound_player::play_sound("underwaterOut", sound_hash(""), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
    let param = human_breath_dot_timer / max(human_breath_dot_maxHoldBreathTime, 0.01)
    soundEvent::set_var(handle, "noairtime", param)


[es (tag=sound, REQUIRE=humanSound, after=(update_sound_group_es,animchar_render_es))]
def human_breath_sound_es(info:UpdateStageInfoAct;
                          human_net_phys_dot_curMoveState : int;
                          human_net_phys_dot_stamina : float;
                          sound_allTags : int64;
                          var sound_group : IPoint3List;
                          sound_paths : ecs::Object;
                          sound_descs : ecs::Object;
                          var human_breath_sound_dot_isBreath : bool&;
                          var human_breath_sound_dot_isLowHealth : bool&;
                          human_breath_sound_dot_breathoutStamina : float;
                          human_breath_sound_dot_loHealthRel : float;
                          is_watched_sound : bool;
                          transform : float3x4;
                          isAlive : bool;
                          isDowned : bool;
                          hitpoints_dot_hp : float;
                          hitpoints_dot_maxHp : float)

  if !isAlive || !is_watched_sound || isDowned
    if human_breath_sound_dot_isBreath
      human_breath_sound_dot_isBreath = false
      human_breath_sound_dot_isLowHealth = false
      sound_player::release_sound(sound_group, sound_hash("breath"))
    return

  let isLowHealth = hitpoints_dot_hp < human_breath_sound_dot_loHealthRel * hitpoints_dot_maxHp
  let isBreath = isLowHealth || human_net_phys_dot_curMoveState == int(HUMoveState EMS_SPRINT)
  let stamina = (isLowHealth || human_breath_sound_dot_isLowHealth) ? 0.0 : human_net_phys_dot_stamina
  human_breath_sound_dot_isLowHealth = isLowHealth

  if isBreath
    if !human_breath_sound_dot_isBreath
      human_breath_sound_dot_isBreath = true
      sound_player::play_sound("sprintBreath", sound_hash("breath"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
    let handle = sound_player::get_sound(sound_group, sound_hash("breath"))
    soundEvent::set_var(handle, "Stamina", stamina)
  elif human_breath_sound_dot_isBreath
    human_breath_sound_dot_isBreath = false
    sound_player::abandon_sound(sound_group, sound_hash("breath"))
    if stamina < human_breath_sound_dot_breathoutStamina
      sound_player::play_sound("sprintBreathOut", sound_hash("breath"), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
