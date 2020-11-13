require ecs
require DagorRandom

[es(tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def effect_scale_randomizer(evt: Event; effect_scale_randomizer_dot_range: float2; var effect_scale_randomizer_dot_scale: float&)
  effect_scale_randomizer_dot_scale = rnd_float(effect_scale_randomizer_dot_range.x, effect_scale_randomizer_dot_range.y)

[es(tag=render, track=effect_scale_randomizer_dot_scale, on_event=(EventEntityCreated, EventComponentsAppear))]
def apply_effect_scale_randomizer(evt: Event; effect_scale_randomizer_dot_scale : float; var effect_dot_scale: float&)
  effect_dot_scale = effect_scale_randomizer_dot_scale
