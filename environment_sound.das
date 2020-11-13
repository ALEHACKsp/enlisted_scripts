require ecs
require soundEvent
require soundSystem

[es (track=entity_sound_dot_enabled, tag=sound)]
def environment_sound_toggle_es(evt:Event;
                                entity_sound_dot_enabled:bool;
                                environment_sound_dot_sound:string;
                                var environment_sound_dot_handle:int&;
                                transform : float3x4)
  soundEvent::release(environment_sound_dot_handle)
  if entity_sound_dot_enabled
    environment_sound_dot_handle = soundEvent::init(environment_sound_dot_sound, "")
    soundEvent::set_pos(environment_sound_dot_handle, transform[3])
    soundEvent::start(environment_sound_dot_handle)


[es (on_event=EventEntityDestroyed, tag=sound)]
def environment_sound_destroy_es(evt:Event; var environment_sound_dot_handle:int&; environment_sound_dot_doAbandon=false)
  if environment_sound_dot_doAbandon
    soundEvent::abandon(environment_sound_dot_handle)
  else
    soundEvent::release(environment_sound_dot_handle)


[es (tag=sound, REQUIRE=movable_environment_sound, no_order)]
def environment_sound_move_es(info:UpdateStageInfoAct;
                              entity_sound_dot_enabled:bool;
                              environment_sound_dot_handle:int;
                              transform : float3x4)
  if entity_sound_dot_enabled
    soundEvent::set_pos(environment_sound_dot_handle, transform[3])


[es (tag=sound, REQUIRE=reverb_environment_sound, no_order)]
def environment_sound_reverb_es(info:UpdateStageInfoAct;
                                environment_sound_dot_handle:int)
  if environment_sound_dot_handle != 0
    soundEvent::set_var(environment_sound_dot_handle, "reverb_indoor", get_reverb_intensity())
