require ecs
require game.es.lut_switcher_common
require DagorShaders
require app
require math
require DagorMath
require player
require DagorSystem

let
  fire_on_screen_endVarId = get_shader_variable_id("fire_on_screen_end_time", true)
  angle_deltaVarId = get_shader_variable_id("fire_on_screen_horizontal_delta", true)

[es(tag=render, on_event=EventEntityDestroyed, REQUIRE=hero)]
def fire_on_screen_reset_es(evt : Event)
  DagorShaders::set_real(fire_on_screen_endVarId, -1.0)

[es (tag=render, no_order, REQUIRE=hero)]
def fire_on_screen_update_es(act : ecs::UpdateStageInfoAct; burning_dot_isBurning : bool; isAlive : bool;
                             camera_dot_prevLookDir : float3 const&; camera_dot_lookDir : float3 const&)
  if !burning_dot_isBurning || !isAlive
    return
  DagorShaders::set_real(fire_on_screen_endVarId, get_shader_global_time_phase(0.0, 0.0))
  var phi_old = atan2(camera_dot_prevLookDir.x, camera_dot_prevLookDir.z)
  var phi_new = atan2(camera_dot_lookDir.x, camera_dot_lookDir.z)
  var delta = phi_new - phi_old
  if delta > PI
    delta -= 2.0*PI
  elif delta < -PI
    delta += 2.0*PI
  delta *= 10.0
  var prev_delta = DagorShaders::get_real(angle_deltaVarId)
  DagorShaders::set_real(angle_deltaVarId, lerp(prev_delta, delta, pow(0.02, 1.0 / min(act.dt, 0.1) / 150.0)))