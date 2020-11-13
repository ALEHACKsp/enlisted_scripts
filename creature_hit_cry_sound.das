require ecs
require soundHash
require game.es.events
require game.es.sound.sound_player
require dm

[es (tag=sound, REQUIRE=creatureHitCrySound)]
def creature_hit_cry_sound_es(evt : EventOnEntityHit; eid : ecs::EntityId;
                              sound_paths : ecs::Object;
                              sound_descs : ecs::Object;
                              transform : float3x4;
                              var sound_group : IPoint3List;
                              isAlive : bool;
                              sound_allTags : int64 = 0l;
                              is_watched_sound : bool = false)
  if eid == evt.victim
    if isAlive && !sound_player::has_sound(sound_group, sound_hash("burningCry"))
      sound_player::play_sound("hitCry", sound_hash(""), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
