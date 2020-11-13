require ecs
require ecs.common
require app
require net
require soundEvent
require soundSystem
require soundHash
require game.es.sound.sound_events
require game.es.sound.sound_player
require DagorSystem
require DagorRandom

def play_melee_event(gun_eid : ecs::EntityId;
                     irq_obj : ecs::Object;
                     var sound_group : IPoint3List;
                     sound_paths : ecs::Object;
                     sound_allTags : int64;
                     is_watched_sound : bool;
                     transform : float3x4)
  var name = sound_player::get_path_string(irq_obj, "name", "")
  if name == ""
    name = get_string(gun_eid, "meleeSoundName", "hands/whoosh")
  if name != ""
    var path : string
    if sound_player::make_path(irq_obj, sound_paths, sound_allTags, is_watched_sound, path)
      sound_player::play_name_path(name, path, sound_hash(""), transform[3], sound_group, is_watched_sound)


[es (tag=sound, REQUIRE=humanSound, no_order)]
def human_sound_melee_update_es(info : UpdateStageInfoAct;
                                sound_paths : ecs::Object;
                                sound_irqs : ecs::Array;
                                sound_allTags : int64;
                                var sound_group : IPoint3List;
                                is_watched_sound : bool;
                                var human_melee_sound_gunEids : ecs::EidList &;
                                var human_melee_sound_attributes : ecs::Point2List &;
                                transform : float3x4)
  assert(length(human_melee_sound_gunEids) == length(human_melee_sound_attributes))
  let time = get_sync_time()
  var idx = length(human_melee_sound_gunEids)
  while idx > 0
    --idx
    if time >= human_melee_sound_attributes[idx].x
      let gun = human_melee_sound_gunEids[idx]
      let irq = int(human_melee_sound_attributes[idx].y)
      erase(human_melee_sound_gunEids, idx)
      erase(human_melee_sound_attributes, idx)
      assert(irq >= 0 && irq < length(sound_irqs))
      let irqObj = get_ecs_object(sound_irqs[irq])
      if irqObj != null
        play_melee_event(gun, *irqObj, sound_group, sound_paths, sound_allTags, is_watched_sound, transform)


[es (tag=sound, REQUIRE=humanSound)]
def human_sound_melee_irq_es(evt : CmdSoundMeleeIrq;
                             sound_paths : ecs::Object;
                             sound_irqs : ecs::Array;
                             sound_allTags : int64;
                             var sound_group : IPoint3List;
                             is_watched_sound : bool;
                             human_weap_dot_gunEids : ecs::EidList const?;
                             human_weap_dot_currentGunSlot : int const?;
                             var human_melee_sound_gunEids : ecs::EidList ?;
                             var human_melee_sound_attributes : ecs::Point2List ?;
                             transform : float3x4)
  if !is_watched_sound && !soundEvent::should_play(transform[3])
    return
  let gun = human_weap_dot_gunEids != null && human_weap_dot_currentGunSlot != null && *human_weap_dot_currentGunSlot >= 0 ? (*human_weap_dot_gunEids)[*human_weap_dot_currentGunSlot] : ecs::INVALID_ENTITY_ID
  let meleeType : string = get_string(gun, "meleeSoundType", "hands")
  if meleeType == ""
    return

  var irqIdx = -1
  for it in sound_irqs
    ++irqIdx
    let irqObj = get_ecs_object(it)
    if irqObj == null || (evt.irq != get_int(irqObj, "irqId") ?? -1)
      continue

    let attrObj = get_ecs_object(irqObj, "attributes")
    if attrObj == null
      continue
/*
    if human_melee_sound_gunEids != null && human_melee_sound_attributes != null
      let meleeDelay = 80
      let voiceDelay = 100
      let voiceChance = 100

      if sound_player::get_path_string(*irqObj, "path", "") == "weaponMelee"
        if length(*human_melee_sound_gunEids) < 16
          push_back(*human_melee_sound_gunEids, gun)
          push_back(*human_melee_sound_attributes, float2(get_sync_time() + float(meleeDelay) * 0.001, float(irqIdx)))

      if sound_player::get_path_string(*irqObj, "path", "") == "voiceFx"
        if length(*human_melee_sound_gunEids) < 16 && rnd_int(0, 100) <= voiceChance
          push_back(*human_melee_sound_gunEids, gun)
          push_back(*human_melee_sound_attributes, float2(get_sync_time() + float(voiceDelay) * 0.001, float(irqIdx)))
      continue
*/
    let weapObj = get_ecs_object(attrObj, meleeType)
    if weapObj != null
      let delayMs = get_int(weapObj, "delay") ?? 0
      if delayMs > 0
        if human_melee_sound_gunEids != null && human_melee_sound_attributes != null && length(*human_melee_sound_gunEids) < 16
          let chance = get_int(weapObj, "chance") ?? -1
          if chance <= 0 || rnd_int(0, 100) <= chance
            push_back(*human_melee_sound_gunEids, gun)
            push_back(*human_melee_sound_attributes, float2(get_sync_time() + float(delayMs) * 0.001, float(irqIdx)))
        continue

      play_melee_event(gun, *irqObj, sound_group, sound_paths, sound_allTags, is_watched_sound, transform)
