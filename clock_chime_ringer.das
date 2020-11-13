require ecs
require app
require math
require DagorTime
require soundEvent
require soundSystem

def get_stage()
  let hms = get_local_time()
  return (hms.x * 60 + hms.y) / 15


[es (tag=sound, no_order)]
def clock_chime_ringer_es(info:UpdateStageInfoAct;
                          var clock_chime_ringer_dot_stage:int &)

  let stage = get_stage()
  if clock_chime_ringer_dot_stage == stage
    return
  if clock_chime_ringer_dot_stage == -1
    clock_chime_ringer_dot_stage = stage
    return
  clock_chime_ringer_dot_stage = stage

  ecs::query() <| $ [es] (var clock_chime_dot_ringHandle : int&; clock_chime_dot_ringSound : string; transform : float3x4)
    soundEvent::abandon(clock_chime_dot_ringHandle)
    if length_sq(get_listener_pos() - transform[3]) < 30.0 * 30.0
      clock_chime_dot_ringHandle = soundEvent::init(clock_chime_dot_ringSound, "")
      let hms = get_local_time()
      soundEvent::set_var(clock_chime_dot_ringHandle, "daytime", float(hms.y > 0 ? 1 : hms.x) + 0.5)
      soundEvent::set_pos(clock_chime_dot_ringHandle, transform[3])
      soundEvent::start(clock_chime_dot_ringHandle)


[es (on_event=EventEntityDestroyed, tag=sound)]
def clock_chime_destroy_es(evt:Event;
                           var clock_chime_dot_ringHandle : int&)

  soundEvent::abandon(clock_chime_dot_ringHandle)
