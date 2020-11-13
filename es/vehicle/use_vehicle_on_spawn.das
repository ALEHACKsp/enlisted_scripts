require ecs
require vehicle
require DagorSystem
require game.es.vehicle.vehicle_events

[es (tag=server, REQUIRE=player)]
def cmd_use_vehicle_on_spawn_es(evt: CmdUseVehiceOnSpawn; eid: ecs::EntityId)
  ecs::query(evt.vehicle) <| $[es](vehicle_seats_components: VehicleSeatsComponents;
                                   vehicle_seats_order: VehicleSeatsOrder;
                                   var vehicle_seats_owners: VehicleSeatsOwners)
    let orders & = vehicle_seats_order.data
    if evt.seatOrderNo >= length(orders)
      logerr("vehicle_seats_order index is out of range ({evt.seatOrderNo} >= {length(orders)})")
      return

    var isPlayer = false
    ecs::query(evt.possessed) <| $[es](possessedByPlr: ecs::EntityId;
                                        var isInVehicle: bool&;
                                        var human_anim_dot_vehicleSelected: ecs::EntityId&)
      isPlayer = possessedByPlr != INVALID_ENTITY_ID
      isInVehicle = true
      human_anim_dot_vehicleSelected = evt.vehicle

    let seatNo = orders[evt.seatOrderNo].seatNo
    let components & = vehicle_seats_components.data
    set_vehicle_seat_component(evt.possessed, components[seatNo], true)

    var owners & = vehicle_seats_owners.data
    var owner & = owners[seatNo]
    owner.isPlayer = isPlayer
    owner.eid = evt.possessed
    owner.player = eid
    owner.squad = evt.squad
