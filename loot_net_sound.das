require ecs
require ecs.common
require app
require soundHash
require game.es.events
require game.es.sound.sound_events

[es (tag=server)]
def on_loot_pickup_net_sound_es(evt:EventOnLootPickup; eid:ecs::EntityId)
  let tag = get_string(evt.itemEid, "item.lootSoundTag", "loot_other")
  sendEvent(eid, [[CmdPlayLootSoundForEnemy hash=sound_hash("pick_{tag}"), time=get_sync_time()]])

[es (tag=server)]
def on_loot_use_net_sound_es(evt : EventOnLootUse; eid:ecs::EntityId)
  let tag = get_string(evt.itemEid, "item.lootSoundTag", "loot_other")
  sendEvent(eid, [[CmdPlayLootSound hash=sound_hash("use_{tag}"), time=get_sync_time()]])

[es (on_event=EventOnContainerLooted, tag=server)]
def on_container_looted_net_sound_es(evt:Event;
                                     container_looted_net_sound_dot_desc:string const;
                                     transform:float3x4)
  ecs::query() <| $ [es (REQUIRE=commonNetSounds)](eid:ecs::EntityId)
    let hash = sound_hash(container_looted_net_sound_dot_desc)
    sendEvent(eid, [[CmdPlayNetSound hash=hash, pos=transform[3], param=0., interval=0., time=get_sync_time()]])
