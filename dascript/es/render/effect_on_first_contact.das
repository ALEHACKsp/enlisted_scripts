require ecs
require fx

[es (on_event=EventFirstContact, tag=render)]
def on_first_contact_effect(evt: Event; effect_dot_effectOnContact: string; transform: float3x4)
  fx::start_effect(effect_dot_effectOnContact, transform, 1.0)