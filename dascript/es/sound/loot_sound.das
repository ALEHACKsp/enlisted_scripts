require ecs
require ecs.common
require app
require soundHash
require soundEvent
require game.es.events
require game.es.sound.sound_events
require game.utils.hero

def play_loot_sound(hash : uint; transform : float3x4; var loot_sound_dot_time : float &; is_watched : bool)
  if get_sync_time() > loot_sound_dot_time + 0.1
    loot_sound_dot_time = get_sync_time()
    if soundEvent::should_play(transform[3])
      broadcastEvent([[CmdPlayCommonSound hash=hash, pos=transform[3], isWatched=is_watched]])

[es (tag=sound)]
def play_loot_sound_es(cmd : CmdPlayLootSound; transform:float3x4; is_watched_sound : bool; var loot_sound_dot_time : float &)
  if get_sync_time() < cmd.time + 5.
    play_loot_sound(cmd.hash, transform, loot_sound_dot_time, is_watched_sound)

[es (tag=sound)]
def play_loot_sound_enemy_es(cmd : CmdPlayLootSoundForEnemy; transform:float3x4; is_watched_sound : bool; var loot_sound_dot_time : float &)
  if get_sync_time() < cmd.time + 5.
    play_loot_sound(cmd.hash, transform, loot_sound_dot_time, is_watched_sound)

[es (tag=sound)]
def on_loot_pickup_sound_es(evt : EventOnLootPickup; transform : float3x4; is_watched_sound : bool; var loot_sound_dot_time : float &)
  let tag = get_string(evt.itemEid, "item.lootSoundTag", "loot_other")
  play_loot_sound(sound_hash("pick_{tag}"), transform, loot_sound_dot_time, is_watched_sound)

[es (tag=sound)]
def on_loot_drop_sound_es(evt:EventOnLootDrop; transform : float3x4; is_watched_sound : bool; var loot_sound_dot_time : float &)
  if is_watched_sound
    let tag = get_string(evt.itemEid, "item.lootSoundTag", "loot_other")
    play_loot_sound(sound_hash("drop_{tag}"), transform, loot_sound_dot_time, is_watched_sound)
