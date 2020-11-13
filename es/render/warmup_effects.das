require ecs
require fx

[es(tag=render, no_order)]
def warmup_effects_update(info : UpdateStageInfoAct; eid : EntityId; warmup_effect_dot_update : FloatList;
                          var warmup_effect_dot_delay : float&)
  if warmup_effect_dot_delay > 0f
    warmup_effect_dot_delay -= info.dt
    return
  for dt in warmup_effect_dot_update
    effects_update(dt)
  destroyEntity(eid)
