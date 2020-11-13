require ecs
require PhysVars

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=render)]
def torso_hider_init_es(evt: Event; char_flags_dot_hasBodyArmorOn: bool; var char_flags_dot_bodyArmorWearVarId: int&; var phys_vars: PhysVars)
  char_flags_dot_bodyArmorWearVarId = register_var(phys_vars, "wears_body_armor", char_flags_dot_hasBodyArmorOn ? 1.0 : 0.0)

[es (tag=render, track=char_flags_dot_hasBodyArmorOn)]
def torso_hider_es(evt: Event; char_flags_dot_hasBodyArmorOn: bool; char_flags_dot_bodyArmorWearVarId: int; var phys_vars: PhysVars)
  set_var(phys_vars, char_flags_dot_bodyArmorWearVarId, char_flags_dot_hasBodyArmorOn ? 1.0 : 0.0)

