require ecs
require app
require DagorMath
require game.es.events

[es (tag=render, REQUIRE=hero)]
def killer_outline(evt : EventEntityDied)
  query(evt.offender) <| $ [es] (var outline_dot_enabled : bool&;
                                 var outline_dot_color : E3DCOLOR&;
                                 var outline_dot_disableAtTime : float&;
                                 var killer_outline_dot_enabled : bool&;
                                 killer_outline_dot_color : E3DCOLOR;
                                 human_anim_dot_vehicleSelected : EntityId;
                                 killer_outline_dot_timeout : float = 5.0)
    if !!human_anim_dot_vehicleSelected
      return
    outline_dot_enabled = true
    outline_dot_color = killer_outline_dot_color
    outline_dot_disableAtTime = get_sync_time() + killer_outline_dot_timeout
    killer_outline_dot_enabled = true


[es (tag=render, no_order)]
def outline_disabler(info : UpdateStageInfoAct;
                     var killer_outline_dot_enabled : bool&;
                     var outline_dot_enabled : bool&;
                     var outline_dot_disableAtTime : float&)
  if killer_outline_dot_enabled && outline_dot_disableAtTime < info.curTime && outline_dot_disableAtTime >= 0.0
    outline_dot_disableAtTime = -1.0
    outline_dot_enabled = false
    killer_outline_dot_enabled = false

[es (tag=render, on_event=EventHeroChanged)]
def outline_disabler_hero_changed(evt : Event;
                                  var killer_outline_dot_enabled : bool&;
                                  var outline_dot_enabled : bool&;
                                  var outline_dot_disableAtTime : float&)
  if killer_outline_dot_enabled
    outline_dot_disableAtTime = -1.0
    outline_dot_enabled = false
    killer_outline_dot_enabled = false

