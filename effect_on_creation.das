require ecs
require fx

[es (on_event=(EventComponentsAppear, EventEntityCreated), tag=render)]
def on_creation_effect(evt: Event; effect_dot_effectOnCreation: string; transform: float3x4)
  fx::start_effect(effect_dot_effectOnCreation, transform, 1.0)
