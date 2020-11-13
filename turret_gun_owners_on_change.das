require ecs
require vehicle
require EnlistedWeapon

[es(on_event=EventOnGunCreated, track=(vehicle_seats_owners, vehicle_seats_player_controls))]
def turret_gun_owners_on_change(event: Event;
                                turret_control_dot_gunEids: EidList;
                                vehicle_seats_owners: VehicleSeatsOwners;
                                vehicle_seats_player_controls: VehicleSeatsPlayerControls)
  for turretNo in iter_range(turret_control_dot_gunEids)
    var gunOwner: EntityId
    for seatNo in iter_range(vehicle_seats_owners.data)
      if can_control_turret(vehicle_seats_player_controls.data[seatNo], turretNo)
        gunOwner = vehicle_seats_owners.data[seatNo].eid;
        break
    setOptional(turret_control_dot_gunEids[turretNo], "gun.owner", gunOwner)