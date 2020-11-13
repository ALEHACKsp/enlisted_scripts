require ecs
require soundEvent
require game.es.events
require RendInst

[es (tag=sound, REQUIRE=humanSound)]
def rendinst_projectile_damage_sound_es(evt:CmdRendinstDamage)
  let riExtraEid = get_ri_extra_eid(evt.handle)
  ecs::query(riExtraEid) <| $ [es] (rendinst_damage_sound_dot_projectile : string)
    soundEvent::oneshot("^dmg={evt.damage}$", rendinst_damage_sound_dot_projectile, evt.pos, 400.0)
