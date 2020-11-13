require ecs
require soundEvent
require math
require EnlistedPlane
require DagorMath

[es (tag=sound, after=plane_engine_sound_es)]
def plane_dive_siren_es(info:UpdateStageInfoAct;
                        plane_net_phys : PlaneActor;
                        transform : float3x4;
                        dive_siren_dot_event : string;
                        dive_siren_dot_threshold : float;
                        var dive_siren_dot_enabled : bool &;
                        var dive_siren_dot_handle : int &;
                        isAlive : bool)
  let spdSq = length_sq(float3(plane_net_phys.phys.vel))
  if isAlive && dive_siren_dot_enabled && spdSq >= dive_siren_dot_threshold * dive_siren_dot_threshold
    if dive_siren_dot_handle == 0
      dive_siren_dot_handle = soundEvent::init(dive_siren_dot_event, "")
      if dive_siren_dot_handle == 0
        dive_siren_dot_enabled = false
      soundEvent::start(dive_siren_dot_handle)
  if dive_siren_dot_handle != 0
    soundEvent::set_pos(dive_siren_dot_handle, transform[3])
    if !isAlive
      soundEvent::release(dive_siren_dot_handle)
    elif !dive_siren_dot_enabled || spdSq < dive_siren_dot_threshold * dive_siren_dot_threshold * 0.9
      soundEvent::abandon(dive_siren_dot_handle)

[es (on_event=EventEntityDestroyed, tag=sound)]
def plane_dive_siren_destroy_es(evt:Event; var dive_siren_dot_handle : int &)
  soundEvent::release(dive_siren_dot_handle)
