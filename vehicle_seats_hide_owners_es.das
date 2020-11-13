require ecs
require ecs.common
require vehicle
require EnlistedWeapon
require PhysVars
require game.utils.hero
require game.es.vehicle.vehicle_seats_common

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_seats_hide_owner_init_es (evt : Event;
                                      [[shared_comp]] vehicle_seats_dot_seats: Array;
                                      var vehicle_seats_hide_owner: BoolList)
  let seatsCount = length(vehicle_seats_dot_seats)
  resize(vehicle_seats_hide_owner, seatsCount)
  for seatNo in range(0, seatsCount)
    let seat = get_ecs_object(vehicle_seats_dot_seats[seatNo])
    vehicle_seats_hide_owner[seatNo] = get_bool(seat, "shouldHideOwner") ?? false


[es (no_order, tag=server, REQUIRE=isInVehicle)]
def vehicle_seats_hide_owners_es (info: UpdateStageInfoAct;
                                  eid: EntityId;
                                  human_anim_dot_vehicleSelected: EntityId;
                                  var isInVehicleHidden: bool&)
  ecs::query(human_anim_dot_vehicleSelected) <| $ [es] (vehicle_seats_hide_owner: BoolList;
                                                        vehicle_seats_owners: VehicleSeatsOwners;
                                                        vehicle_seats_hatch_nodes: VehicleSeatsHatchNodes)
    let seatNo = find_seat_with_owner(vehicle_seats_owners, eid)
    if seatNo >= 0
      let hatchNodeData & = vehicle_seats_hatch_nodes.data[seatNo]
      let hasHatch = hatchNodeData.isNodesValid
      let isHatchClosed = hasHatch && hatchNodeData.openPos <= 0.f
      let isPlayer = vehicle_seats_owners.data[seatNo].isPlayer
      let canHide = !isPlayer || !hasHatch || isHatchClosed
      isInVehicleHidden = canHide && vehicle_seats_hide_owner[seatNo]
