require ecs
require ecs.common
require soundHash
require game.es.sound.sound_player
require game.es.events

[es (tag=sound, REQUIRE=humanSound)]
def install_weap_mod_sound_es(evt : EventOnInstallWeapMod;
                              sound_allTags : int64;
                              var sound_group : IPoint3List;
                              sound_paths : ecs::Object;
                              sound_descs : ecs::Object;
                              is_watched_sound : bool;
                              transform : float3x4)
  if is_watched_sound && evt.withSfx
    let name = evt.slotTag != "" ? "installWeapMod" : "uninstallWeapMod"
    sound_player::play_sound(name, sound_hash(""), sound_paths, sound_descs, sound_allTags, is_watched_sound, transform[3], sound_group)
