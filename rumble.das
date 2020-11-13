require ecs
require dm
require DaWeapons
require game.utils.hero
require game.es.events
require game.es.input.input_common

[es (tag=input)]
def rumble_on_damage(evt: EventOnEntityHit)
  let victim      = evt.victim
  let damageDesc& = evt.damageDesc
  if !victim || victim != get_controlled_hero()
    return

  if damageDesc.damageType == DamageType DM_MELEE
    do_rumble("meleeDamage")
  elif damageDesc.damageType == DamageType DM_BACKSTAB
    do_rumble("backstabDamage")
  elif damageDesc.damageType == DamageType DM_EXPLOSION
    do_rumble("explosionDamage")
  elif damageDesc.damageType == DamageType DM_ZONE
    do_rumble("zoneDamage")
  elif damageDesc.damageType == DamageType DM_COLLISION
    do_rumble("collisionDamage")
  elif damageDesc.damageType == DamageType DM_HOLD_BREATH
    do_rumble("holdBreathDamage")
  elif damageDesc.damageType == DamageType DM_FIRE
    do_rumble("fireDamage")
  elif damageDesc.damageType == DamageType DM_BARBWIRE
    do_rumble("barbwireDamage")
  else
    do_rumble("projectileDamage")

[es (tag=input, after=after_net_phys_sync, before=clear_gun_launch_events_es, REQUIRE=(isTurret, mainTurret))]
def turret_rumble_on_shooting(info: UpdateStageInfoAct; gun_dot_owner: ecs::EntityId; gun_launch_events: GunLauchEvents)
  if !!gun_dot_owner && gun_dot_owner == get_controlled_hero() && gun_launch_events.launchEvents.length > 0
    do_rumble("mainTurretShot")

[es (tag=input, REQUIRE=concussionAffect, on_event=(EventEntityCreated, EventComponentsAppear))]
def rumble_on_concussion(evt: Event; game_effect_dot_attachedTo: EntityId)
  if !!game_effect_dot_attachedTo && game_effect_dot_attachedTo == get_controlled_hero()
    do_rumble("concussion")