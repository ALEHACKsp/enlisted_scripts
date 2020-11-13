require ecs
require player
require DagorConsole
require DagorMath

require game.utils.hero
require game.es.vehicle.vehicle_events

[console_cmd(name="vehicle.explosion")]
def vehicle_explosion()
  let vehicleEid = get_Eid(get_controlled_hero(), "human_anim.vehicleSelected") ?? INVALID_ENTITY_ID
  sendEvent(vehicleEid, [[EventExplosionFatal offender=INVALID_ENTITY_ID]])

[console_cmd(name="vehicle.explosion_crash")]
def vehicle_explosion_crash()
  let vehicleEid = get_Eid(get_controlled_hero(), "human_anim.vehicleSelected") ?? INVALID_ENTITY_ID
  sendEvent(vehicleEid, [[EventCrashExplosionFatal offender=INVALID_ENTITY_ID]])