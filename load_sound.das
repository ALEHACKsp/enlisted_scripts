require ecs
require soundSystem
require soundHash
require game.es.sound.sound_events

[es (tag=sound)]
def load_sound_toggle_es(e:EventOnSoundGameToggle;
                         load_sound_dot_gameTag:string;
                         var load_sound_dot_isLoaded:bool&)
  if e.hash == sound_hash(load_sound_dot_gameTag)
    load_sound_dot_isLoaded = e.isValid


[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=sound)]
def load_sound_create_es(evt:Event;
                         load_sound_dot_gameTag:string;
                         var load_sound_dot_isLoaded:bool&)
  load_sound_dot_isLoaded = soundSystem::is_game_valid(load_sound_dot_gameTag)
