require ecs
require PhysVars

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=render)]
def human_anim_bayonet_init(evt: Event; var human_anim_dot_isBayonetAttachedVarId: int&; var phys_vars: PhysVars)
  human_anim_dot_isBayonetAttachedVarId = register_var(phys_vars, "is_bayonet_attached", 0.0)

[es (before=human_anim_es, tag=render)]
def human_anim_bayonet(info : UpdateStageInfoAct;
                       human_anim_dot_isBayonetAttachedVarId: int; var phys_vars: PhysVars;
                       human_weap_dot_currentGunModEid: EntityId)
  let hasBayonet = has(human_weap_dot_currentGunModEid, "gunAttachable.isBayonet")
  set_var(phys_vars, human_anim_dot_isBayonetAttachedVarId, hasBayonet ? 1.0 : 0.0)

