require ecs
require vehicle
require game.es.vehicle.vehicle_events

[es (tag=server, on_event=EventEntityDestroyed)]
def vehicle_seats_kick_from_destroyed(evt : Event;
                                      eid : EntityId;
                                      vehicle_seats_owners : VehicleSeatsOwners)
  let owners & = vehicle_seats_owners.data
  for owner in owners
    sendEventImmediate(eid, [[CmdKickFromVehicle eid=owner.eid]])
