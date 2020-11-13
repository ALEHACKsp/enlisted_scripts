require ecs
require soundEvent

[es (tag=sound, track=door_operations_dot_curState)]
def door_sound_es(evt : Event;
                  door_operations_dot_curState : bool;
                  door_operations_dot_openedSound : string;
                  door_operations_dot_closedSound : string;
                  transform : float3x4)
  soundEvent::oneshot(door_operations_dot_curState ? door_operations_dot_openedSound : door_operations_dot_closedSound, "", transform[3])
