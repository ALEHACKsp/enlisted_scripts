require ecs
require dm
require vehicle
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common

def find_first_proper_seat_no(orders; owners): int
  for orderNo in iter_range(orders)
    let order: auto const& = orders[orderNo]
    if !order.canPlaceManually
      continue
    let seatNo = order.seatNo
    let owner: auto const& = owners[seatNo]
    if owner.eid == INVALID_ENTITY_ID || !owner.isPlayer
      return seatNo
  return -1

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventComponentChanged, track=vehicle_seats_owners)]
def validate_vehicle_seat_owners(evt: Event; eid: ecs::EntityId; vehicle_seats_owners: VehicleSeatsOwners; vehicle_seats_order: VehicleSeatsOrder)
  let owners & = vehicle_seats_owners.data
  let orders & = vehicle_seats_order.data
  for seatNo in iter_range(owners)
    let owner: auto const& = owners[seatNo]
    if owner.eid != INVALID_ENTITY_ID && owner.isPlayer && !can_place_manually(seatNo, orders)
      let properSeatNo = find_first_proper_seat_no(orders, owners)
      if properSeatNo >= 0
        sendEvent(eid, [[CmdVehicleSwapSeats seatNo1=seatNo, seatNo2=properSeatNo]])
