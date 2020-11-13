require ecs
require vehicle
require game.es.vehicle.vehicle_events

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def seat_visibility_init(evt : Event;
                        [[shared_comp]] vehicle_seats_dot_seats : Array;
                        var vehicle_seats_limited_visibility : ecs::IntList)
  resize(vehicle_seats_limited_visibility, length(vehicle_seats_dot_seats))

[es (tag=server, on_event=EventComponentChanged, track=vehicle_seats_owners, track=vehicle_seats_limited_visibility)]
def seat_visibility_changed(evt : Event;
                            vehicle_seats_owners : VehicleSeatsOwners const;
                            vehicle_seats_limited_visibility : ecs::IntList)
  let owners & = vehicle_seats_owners.data
  for seatNo in iter_range(owners)
    let owner : auto const& = owners[seatNo]
    if owner.eid == ecs::INVALID_ENTITY_ID
      continue

    let isHidden = get_bool(owner.eid, "isInVehicleHidden") ?? false
    let isVisionLimited = seatNo < length(vehicle_seats_limited_visibility) ? vehicle_seats_limited_visibility[seatNo] > 0 : false
    setOptional(owner.eid, "isBlinded", isHidden && isVisionLimited)

[es (tag=server, on_event=EventComponentChanged, track=isInVehicle)]
def seats_visibility_enter(evt : Event;
                           isInVehicle : bool;
                           var isBlinded : bool&)
  if !isInVehicle
    isBlinded = false;
