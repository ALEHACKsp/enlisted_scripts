require ecs
require DagorMath
require DagorRandom
require game.es.effects.effect_controller_common

[es(tag=server, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE="effect_controller.randomizeStartState")]
def effect_controller_randomize_state(evt : Event; var effect_controller_dot_state: int&; effect_controller_dot_states: Array)
  effect_controller_dot_state = rnd_int(0, length(effect_controller_dot_states) - 1)

[es(tag=server, no_order)]
def effect_controller(info: UpdateStageInfoAct;
                      var effect_controller_dot_state: int&;
                      var effect_controller_dot_stateTimes: float2&;
                      effect_controller_dot_states: Array)
  if info.curTime >= effect_controller_dot_stateTimes.y
    effect_controller_dot_state = (effect_controller_dot_state + 1) % length(effect_controller_dot_states)
    let stateParams = get_effect_state_params(effect_controller_dot_states, effect_controller_dot_state)
    effect_controller_dot_stateTimes.x = effect_controller_dot_stateTimes.y // prev end is new start
    effect_controller_dot_stateTimes.y = effect_controller_dot_stateTimes.x + rnd_float(stateParams.time.x, stateParams.time.y)

[es(tag=render, no_order)]
def effect_spawnrate_controller(info: UpdateStageInfoAct;
                                effect_controller_dot_state: int;
                                effect_controller_dot_stateTimes: float2;
                                effect_controller_dot_states: Array;
                                var effect_dot_spawnRate: float&)
  let stateParams = get_effect_state_params(effect_controller_dot_states, effect_controller_dot_state)
  effect_dot_spawnRate = cvt(info.curTime, effect_controller_dot_stateTimes.x, effect_controller_dot_stateTimes.y,
                                           stateParams.spawnRate.x,            stateParams.spawnRate.y)
