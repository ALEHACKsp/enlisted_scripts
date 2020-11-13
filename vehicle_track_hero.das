require ecs
require ecs.common
require vehicle
require game.utils.hero
require game.es.vehicle.vehicle_seats_common


[es (on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventHeroChanged, track=vehicle_seats_owners, tag=gameClient, REQUIRE_NOT=heroVehicle)]
def vehicle_without_hero_es(evt : Event; eid : EntityId; vehicle_seats_owners : VehicleSeatsOwners)
  if is_hero_in_vehicle(vehicle_seats_owners)
    // If new vehicle was created while our hero was in some other vehicle
    // then this comes in before vehicle_with_hero_es, so we must remove
    // vehicle_with_hero template here because we need to make sure that there're never
    // two vehicles with heroVehicle at any point in time.
    // Note that es order / es separation won't help here, since these are triggered by different events.
    query() <| $ [es (REQUIRE=heroVehicle)](eid: EntityId)
      removeSubTemplate(eid, "vehicle_with_hero")
    addSubTemplate(eid, "vehicle_with_hero")


[es (on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventHeroChanged, track=vehicle_seats_owners, tag=gameClient, REQUIRE=heroVehicle)]
def vehicle_with_hero_es(evt : Event; eid : EntityId; vehicle_seats_owners : VehicleSeatsOwners)
  if !is_hero_in_vehicle(vehicle_seats_owners)
    removeSubTemplate(eid, "vehicle_with_hero")


[es (tag=gameClient, on_event=(EventComponentsAppear,EventHeroChanged), track=human_anim_dot_vehicleSelected)]
def track_vehicle_with_watched(evt : Event; watchedByPlr, human_anim_dot_vehicleSelected : EntityId)
  query() <| $ [es (REQUIRE=vehicleWithWatched)](eid: EntityId)
    removeSubTemplate(eid, "vehicle_with_watched")
  if !!watchedByPlr && !!human_anim_dot_vehicleSelected
    addSubTemplate(human_anim_dot_vehicleSelected, "vehicle_with_watched")

[es (tag=gameClient, on_event=EventComponentsDisappear, REQUIRE=(watchedByPlr,human_anim_dot_vehicleSelected))]
def clear_vehicle_with_watched(evt : Event; eid : EntityId)
  let disappearEid = eid
  let isAnotherWatched = find_query() <| $ [es (REQUIRE=watchedByPlr)] (eid : EntityId)
    return eid != disappearEid
  if !isAnotherWatched
    query() <| $ [es (REQUIRE=vehicleWithWatched)](eid: EntityId)
      removeSubTemplate(eid, "vehicle_with_watched")
