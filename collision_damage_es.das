require ecs
require DagorMath
require dm
require app
require game.es.events
require EnlistedHuman
require vehicle
require game.utils.team
require math.base
require HumanPhys

def calc_collision_damage(delta_vel: float;
                          vel_thres: float;
                          vel_mult: float;
                          vel_pow: float) : float
  if delta_vel < vel_thres
    return 0.f
  return pow(delta_vel - vel_thres, vel_pow) * vel_mult

[es (tag=server)]
def collision_damage_vehicle(evt: EventOnCollision;
                             eid: EntityId;
                             team: int;
                             collision_damage_dot_threshold: float;
                             collision_damage_dot_velDeltaMult: float;
                             collision_damage_dot_velDeltaPower: float;
                             collision_damage_dot_pushThreshold: float;
                             collision_damage_dot_pushVelDeltaMult: float;
                             collision_damage_dot_pushVelDeltaPower: float;
                             hitpoints_dot_hp: float;
                             human_net_phys: HumanActor;
                             collision_damage_dot_friendDamageMult: float;
                             collision_damage_dot_lastVehicleImmunity: float;
                             collision_damage_dot_inVehicleDamageMult: float;
                             collision_damage_dot_crawlMult: float;
                             collision_damage_dot_downedMult: float;
                             vehicle_dot_lastEid: EntityId ? = null;
                             vehicle_dot_lastTime: float = 0.f;
                             isInVehicle: bool = false)
  let offenderVel = evt.cvel
  let offenderSpd = length(offenderVel)
  if !isInVehicle && offenderSpd < collision_damage_dot_threshold && offenderSpd < collision_damage_dot_pushThreshold
    return
  let offender = evt.offender
  if !isInVehicle && vehicle_dot_lastEid != null && *vehicle_dot_lastEid == offender && vehicle_dot_lastTime + collision_damage_dot_lastVehicleImmunity > get_sync_time()
    return
  let dv = evt.vel
  let deltaSpd = length(dv);
  var dmg = calc_collision_damage(deltaSpd, collision_damage_dot_threshold,
                                        collision_damage_dot_velDeltaMult, collision_damage_dot_velDeltaPower)
  if dmg <= 0.f
    let standingVelDiff = offenderVel - human_net_phys.phys.currentState.standingVelocity
    let threshold = 0.4f
    if length_sq(standingVelDiff) > square(threshold)
      let dt = evt.dt
      dmg = dt * calc_collision_damage(offenderSpd, collision_damage_dot_pushThreshold,
                                      collision_damage_dot_pushVelDeltaMult, collision_damage_dot_pushVelDeltaPower)
  let driver = offender != INVALID_ENTITY_ID ? get_vehicle_driver(offender) : INVALID_ENTITY_ID
  let isFriendly = is_teams_friendly(team, get_int(driver, "team") ?? TEAM_UNASSIGNED)
  if driver != INVALID_ENTITY_ID && isFriendly
    dmg *= collision_damage_dot_friendDamageMult
  if isInVehicle
    dmg *= collision_damage_dot_inVehicleDamageMult
  elif driver != INVALID_ENTITY_ID && !isFriendly
    // Not in vehicle and offender is not a friendly driver
    // this means a vehicle runs over us, if we're in crawl or downed state apply
    // additional damage, this should kill a lot faster.
    if human_net_phys.phys.currentState.isCrawl
      dmg *= collision_damage_dot_crawlMult
    elif human_phys_state_get_is_downed(human_net_phys.phys.currentState)
      dmg *= collision_damage_dot_downedMult
  let maxDmgPercent = evt.damage
  if maxDmgPercent >= 0.0f
    dmg = min(dmg, hitpoints_dot_hp * maxDmgPercent)
  if dmg <= 0.f
    return;
  let pos = evt.pos
  damage_entity(eid, offender, DamageDesc(DamageType DM_COLLISION, dmg, pos, -dv))

[es (tag=server, REQUIRE=collision_damage_dot_threshold)]
def collision_damage(evt: CmdCollisionDamage;
                     eid: EntityId)
  let dmg = evt.damage
  if dmg <= 0.f
    return
  let pos = evt.pos
  let offender = evt.offender
  damage_entity(eid, offender, DamageDesc(DamageType DM_COLLISION, dmg, pos))