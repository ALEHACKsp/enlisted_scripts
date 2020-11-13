require ecs
require ecs.common
require app
require vehicle

[es (tag=gameClient, on_event=EventEntityCreated)]
def entities_in_victim_tank_es (evt: Event;
                                hitcamera_dot_target: EntityId;
                                hitcamera_dot_crew_hp_after_hit: IntList;
                                var hitcamera_dot_deadMembers: int&;
                                var hitcamera_dot_totalMembersBeforeShot: int&)
  var totalCrewCount = 0
  var deadCrewCount = 0
  query(hitcamera_dot_target) <| $ [es](vehicle_seats_owners: VehicleSeatsOwners)
    let owners & = vehicle_seats_owners.data
    for seatNo in iter_range(owners)
      let owner & = owners[seatNo]
      let hp = hitcamera_dot_crew_hp_after_hit[seatNo]
      if !!owner.eid
        totalCrewCount++
        if hp == 0
          deadCrewCount++
  hitcamera_dot_deadMembers = deadCrewCount
  hitcamera_dot_totalMembersBeforeShot = totalCrewCount
