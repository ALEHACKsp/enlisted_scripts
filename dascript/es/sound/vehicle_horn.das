require ecs
require ecs.common
require app
require game.es.sound.sound_events
require game.es.sound.sound_player
require soundEvent
require soundHash

[es (tag=sound)]
def on_cmd_vehicle_sound_horn_sound(evt : CmdVehicleSoundHorn;
                                    entity_sound_dot_enabled : bool;
                                    var vehicle_horn_sound_dot_endTime : float &;
                                    sound_paths : ecs::Object;
                                    sound_descs : ecs::Object;
                                    var sound_group : IPoint3List;
                                    is_watched_sound : bool;
                                    transform : float3x4;
                                    vehicle_horn_sound_dot_note : int = 0)
  if entity_sound_dot_enabled
    if evt.enable && evt.end > 0.0
      let h = sound_player::play_sound("horn", sound_hash("horn"), sound_paths, sound_descs, int64(0), is_watched_sound, transform[3], sound_group, true, 0.0)
      soundEvent::set_var(h, "note", float(vehicle_horn_sound_dot_note))
      soundEvent::start(h)
      vehicle_horn_sound_dot_endTime = evt.end
    else
      sound_player::abandon_sound(sound_group, sound_hash("horn"))
      vehicle_horn_sound_dot_endTime = 0.0

[es (tag=sound, no_order)]
def vehicle_horn_sound_end_es(info : UpdateStageInfoAct;
                              var sound_group : IPoint3List;
                              var vehicle_horn_sound_dot_endTime : float &)
  if vehicle_horn_sound_dot_endTime > 0.0
    if info.curTime >= vehicle_horn_sound_dot_endTime
      sound_player::abandon_sound(sound_group, sound_hash("horn"))
      vehicle_horn_sound_dot_endTime = 0.0
