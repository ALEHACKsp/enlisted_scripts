require ecs
require soundEvent
require soundSystem
require Dacoll

[es (tag=sound, no_order)]
def underwater_sound_es(info:UpdateStageInfoAct;
                        underwater_sound_dot_sound:string;
                        var underwater_sound_dot_handle:int &;
                        var underwater_sound_dot_frame:int &;
                        var underwater_sound_dot_underwater:bool &)
  ++underwater_sound_dot_frame
  if (underwater_sound_dot_frame & 3) != 0
    return
  var waterLevel = 0.0
  let pos = get_listener_pos()
  if traceht_water(pos, waterLevel)
    if underwater_sound_dot_underwater && pos.y > waterLevel + 0.1
      underwater_sound_dot_underwater = false
      soundEvent::abandon(underwater_sound_dot_handle)
    elif !underwater_sound_dot_underwater && pos.y < waterLevel
      underwater_sound_dot_underwater = true
      soundEvent::abandon(underwater_sound_dot_handle)
      underwater_sound_dot_handle = soundEvent::init(underwater_sound_dot_sound)
      soundEvent::start(underwater_sound_dot_handle)


[es (on_event=EventEntityDestroyed, tag=sound)]
def underwater_sound_destroy_es(evt:Event; var underwater_sound_dot_handle:int&)
  soundEvent::release(underwater_sound_dot_handle)
