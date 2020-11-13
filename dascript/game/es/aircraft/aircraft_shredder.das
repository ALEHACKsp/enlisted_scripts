require ecs
require app
require vehicle
require game.es.vehicle.vehicle_events

[es (tag=server, no_order, REQUIRE=airplane)]
def destroy_exploded_aircraft(info: UpdateStageInfoAct;
                              eid: EntityId;
                              isExploded: bool;
                              var destroyExplodedAtTime: float&;
                              destroyExplodedTimeout: float = 1.0f;
                              vehicle_seats_owners: VehicleSeatsOwners)
  if !isExploded
    return

  if destroyExplodedAtTime < 0.f
    destroyExplodedAtTime = get_sync_time() + destroyExplodedTimeout
    return

  if info.curTime < destroyExplodedAtTime
    return

  let owners & = vehicle_seats_owners.data
  for owner in owners
    destroyEntity(owner.eid)

  destroyEntity(eid)