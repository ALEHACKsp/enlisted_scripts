require app
require ecs
require soundHash
require soundEvent
require game.es.sound.sound_player

[es (tag=sound, track=building_action_dot_target)]
def building_destroy_sound_track_es(evt : Event;
                                    building_action_dot_target : EntityId;
                                    var sound_group : IPoint3List;
                                    transform : float3x4)
  sound_player::abandon_sound(sound_group, sound_hash("buildingDisassemble"))
  query(building_action_dot_target) <| $ [es](building_destroy_dot_disassembleSound : string)
    sound_player::play_name_path("", building_destroy_dot_disassembleSound, sound_hash("buildingDisassemble"), transform[3], sound_group, false)

[es (tag=sound, on_event=EventEntityDestroyed)]
def building_destroy_sound_es(evt : Event;
                              building_destroy_dot_destroySound : string;
                              transform : float3x4)
  if soundEvent::should_play(transform[3])
    soundEvent::oneshot(building_destroy_dot_destroySound, "", transform[3])
