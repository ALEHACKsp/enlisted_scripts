require ecs
require ecs.common
require game.es.events
require math
require dm
require fx

[es(tag=render, REQUIRE=watchedByPlr)]
def on_armor_hit_fx_effect(evt: EventOnEntityHit; eid : EntityId; [[shared_comp]] visual_armor_hit_dot_fxEffects : Array)
  let armorMult : float = evt.damageDesc.armorMult
  if evt.offender == eid && evt.damageDesc.deltaHp > 0.0 && evt.damageDesc.damageType == DamageType DM_PROJECTILE && armorMult < 1.0
    for it in visual_armor_hit_dot_fxEffects
      let obj = get_ecs_object(it)
      let name = get_string(obj, "fxName", "")
      if name != "" && get_float(obj, "armorAmount") ?? 0.0 <= 1.0 - armorMult
        var tm: float3x4
        let hitDir = normalize(-evt.damageDesc.hitDir)
        tm[1] = hitDir
        tm[2] = cross(hitDir, float3(0., 1., 0.))
        tm[0] = cross(hitDir, tm[2])
        tm[3] = evt.damageDesc.hitPos + hitDir * 0.05
        fx::start_effect(name, tm, 1.0)
        break
