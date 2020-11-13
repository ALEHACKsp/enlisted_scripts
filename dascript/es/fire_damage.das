require ecs
require dm
require math
require app

[es (tag=server, track=burning_dot_isBurning)]
def fire_damage_track_burning(evt : Event;
                              burning_dot_isBurning : bool;
                              var burning_dot_nextDamageAtTime : float&;
                              burning_dot_updateInterval : float)
  burning_dot_nextDamageAtTime = burning_dot_isBurning ? get_sync_time() + burning_dot_updateInterval : -1.0

[es (tag=server, before=hitpoints_es)]
def fire_damage(info : ecs::UpdateStageInfoAct;
                eid : EntityId;
                transform : float3x4;
                var burning_dot_isBurning : bool&;
                var burning_dot_force : float&;
                var burning_dot_tickIncrement : float&;
                var burning_dot_nextDamageAtTime : float&;
                burning_dot_decrease : float;
                burning_dot_damagePerSecond : float;
                burning_dot_maxForce : float;
                burning_dot_isPuttingOut : bool;
                burning_dot_putOutDamageMult : float;
                burning_dot_updateInterval : float;
                entity_mods_dot_fireDamageMult : float = 1.0;
                burning_dot_offender : EntityId = ecs::INVALID_ENTITY_ID)
  if burning_dot_nextDamageAtTime < 0.f || info.curTime < burning_dot_nextDamageAtTime
    return

  burning_dot_nextDamageAtTime += burning_dot_updateInterval
  let dt = burning_dot_updateInterval

  var increment = burning_dot_tickIncrement
  burning_dot_tickIncrement = 0.0

  let pos = transform[3]
  var damagePerSecond = burning_dot_damagePerSecond
  if burning_dot_isPuttingOut
    damagePerSecond *= burning_dot_putOutDamageMult
  let offender = burning_dot_offender != ecs::INVALID_ENTITY_ID ? burning_dot_offender : eid
  let damage = dt * damagePerSecond * entity_mods_dot_fireDamageMult
  let dmDesc : DamageDesc = DamageDesc(DamageType DM_FIRE, damage, pos)
  damage_entity(eid, offender, dmDesc)

  let burningForce = burning_dot_force + increment - dt * burning_dot_decrease
  burning_dot_force = min(burning_dot_maxForce, burningForce)
  if burning_dot_force <= 0.0
    burning_dot_force = 0.0
    burning_dot_isBurning = false