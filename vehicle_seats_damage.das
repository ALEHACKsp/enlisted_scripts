require ecs
require vehicle
require math
require math.base
require game.es.events

[es(after=after_net_phys_sync, before=vehicle_acceleration_es)]
def vehicle_seats_collision_damage_es(info: UpdateStageInfoAct;
                                      eid: EntityId;
                                      vehicle_seats_owners: VehicleSeatsOwners;
                                      net_phys_dot_atTick: int;
                                      net_phys_dot_currentStateVelocity: float3;
                                      net_phys_dot_previousStateVelocity: float3;
                                      vehicle_acceleration_dot_tick: int;
                                      transform: float3x4;
                                      vehicle_seat_damage_dot_minVelocity: float;
                                      vehicle_seat_damage_dot_velocityMult: float;
                                      vehicle_seat_damage_dot_maxDmgPercent: float)
  if net_phys_dot_atTick == vehicle_acceleration_dot_tick
    return
  let prevVelocity = net_phys_dot_previousStateVelocity
  let curVelocity = net_phys_dot_currentStateVelocity
  let deltaVel = curVelocity - prevVelocity
  let deltaSpdSq = length_sq(deltaVel)
  if deltaSpdSq < square(vehicle_seat_damage_dot_minVelocity)
    return
  let owners & = vehicle_seats_owners.data
  for owner in owners
    if owner.eid == INVALID_ENTITY_ID
      continue
    sendEvent(owner.eid, [[EventOnCollision vel=deltaVel * vehicle_seat_damage_dot_velocityMult,
                                            pvel=prevVelocity, pos=transform[3], offender=eid,
                                            cvel=curVelocity, dt=info.dt,
                                            damage=vehicle_seat_damage_dot_maxDmgPercent]])
