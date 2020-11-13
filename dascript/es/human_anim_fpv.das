require ecs
require PhysVars

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=render)]
def human_anim_fpv_init(evt: Event; var human_anim_dot_isFpvVarId: int&; var phys_vars: PhysVars)
  human_anim_dot_isFpvVarId = register_var(phys_vars, "is_fpv", 0.0)

[es (before=human_anim_es, tag=render)]
def human_anim_fpv(info : UpdateStageInfoAct; isCockpitCam: bool; camera_dot_active: bool)
  if !camera_dot_active
    return
  ecs::query() <| $ [es(REQUIRE=cockpitEntity)](var phys_vars: PhysVars; human_anim_dot_isFpvVarId: int)
    set_var(phys_vars, human_anim_dot_isFpvVarId, isCockpitCam ? 1.0 : 0.0)

