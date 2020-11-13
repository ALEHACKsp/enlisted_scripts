require ecs
require PhysVars

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=render)]
def hair_hider_init_es(evt: Event; char_flags_dot_hasHeadwearOn: bool; var char_flags_dot_headwearVarId: int&; var phys_vars: PhysVars)
  char_flags_dot_headwearVarId = register_var(phys_vars, "wears_hat", char_flags_dot_hasHeadwearOn ? 1.0 : 0.0)

[es (tag=render, track=char_flags_dot_hasHeadwearOn)]
def hair_hider_es(evt: Event; char_flags_dot_hasHeadwearOn: bool; char_flags_dot_headwearVarId: int; var phys_vars: PhysVars)
  set_var(phys_vars, char_flags_dot_headwearVarId, char_flags_dot_hasHeadwearOn ? 1.0 : 0.0)
