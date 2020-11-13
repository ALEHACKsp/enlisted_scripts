require ecs
require ecs.common
require soundHash
require soundEvent
require game.es.sound.sound_player

[es (track=human_inventory_dot_entityToUse, tag=sound, REQUIRE=humanSound)]
def human_use_item_sound_es(evt : Event;
                            human_inventory_dot_entityToUse : ecs::EntityId;
                            var sound_group : IPoint3List;
                            is_watched_sound : bool;
                            transform : float3x4)
  sound_player::abandon_sound(sound_group, sound_hash("loot"))
  if human_inventory_dot_entityToUse != INVALID_ENTITY_ID
    if soundEvent::should_play(transform[3])
      ecs::query(human_inventory_dot_entityToUse) <| $ [es] (item_dot_lootSoundTag : string)
        ecs::query() <| $ [es] (net_sound_dot_descs:Object)
          let hash = sound_hash("activate_{item_dot_lootSoundTag}")
          for it in net_sound_dot_descs
            if sound_hash(it.key) == hash
              var obj:Object const& = deref(get_ecs_object(it.value))
              let nameRef = is_watched_sound ? (has(obj, "hero") ? obj["hero"] : obj["event"]) : (has(obj, "enemy") ? obj["enemy"] : obj["event"])
              if nameRef != null
                let name = string(deref(get_ecs_string(deref(nameRef))))
                sound_player::play_name_path(name, "", sound_hash("loot"), transform[3], sound_group, is_watched_sound)
              return
