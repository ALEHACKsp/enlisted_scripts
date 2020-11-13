require ecs
require DagorMath
require math
require app
require soundSystem
require game.es.sound.sound_events


[es (tag=sound)]
def birds_sound_on_shot_es(evt : EventOnGunSound;
                           var birds_sound_dot_noiseTime : float &)
  let actionRange = 250.0
  if length_sq(get_listener_pos() - evt.pos) < actionRange * actionRange
    birds_sound_dot_noiseTime = get_sync_time()


[es (tag=sound, no_order)]
def birds_sound_es(info : UpdateStageInfoAct;
                   birds_sound_dot_noiseTime : float;
                   var birds_sound_dot_var : float &;
                   birds_sound_dot_timeRange : float2 const&)
  birds_sound_dot_var = cvt(info.curTime - birds_sound_dot_noiseTime, birds_sound_dot_timeRange.x, birds_sound_dot_timeRange.y, 1.0, 0.0)
