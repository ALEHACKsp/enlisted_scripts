require vehicle
require ecs
require app
require game.es.vehicle.vehicle_events
require math.base

[es (tag=server, on_event=EventComponentChanged, track=vehicle_seats_owners)]
def vehicle_inactive_update_timer_es(evt: Event;
                                     vehicle_seats_owners: VehicleSeatsOwners;
                                     var inactiveTimer: float&;
                                     inactiveDeleteTimer: float)
  var needDestroy = true
  let owners & = vehicle_seats_owners.data
  for owner in owners
    if owner.eid != INVALID_ENTITY_ID
      needDestroy = false
      break
  inactiveTimer = needDestroy ? get_sync_time() + inactiveDeleteTimer : 0.0;

[es (tag=server, no_order)]
def vehicle_respawn_delete_inactive_es(info: UpdateStageInfoAct;
                                       eid: ecs::EntityId;
                                       inactiveTimer: float;
                                       lastOffender : EntityId = INVALID_ENTITY_ID)
  if inactiveTimer > 0.0 && info.curTime > inactiveTimer
    sendEvent(eid, [[EventExplosionFatal offender=lastOffender]])
    removeSubTemplate(eid, "destroy_inactive_vehicle")

[es (tag=server, no_order)]
def vehicle_shredder_distance_check_es(info: UpdateStageInfoAct;
                                       ownedBySquad: EntityId;
                                       transform: float3x4;
                                       destroyTimerCheckDistance: float;
                                       inactiveDeleteTimer: float;
                                       var inactiveTimer: float&)
  if inactiveTimer <= 0.0
    return
  let vehiclePos = transform[3]
  ecs::find_query() <| $ [es] (squad_member_dot_squad: ecs::EntityId; transform: float3x4; isAlive: bool)
    if isAlive && ownedBySquad == squad_member_dot_squad && length_sq(transform[3] - vehiclePos) < square(destroyTimerCheckDistance)
      inactiveTimer = get_sync_time() + inactiveDeleteTimer
      return true
    return false