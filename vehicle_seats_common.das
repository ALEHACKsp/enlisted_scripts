options remove_unused_symbols = false
module vehicle_seats_common
require ecs
require ecs.common
require DagorMath
require player
require vehicle
require game.utils.hero


def find_seat_with_owner(vehicle_seats_owners: VehicleSeatsOwners; eid: EntityId)
  let seatsCount = length(vehicle_seats_owners.data)
  for seatNo in range(0, seatsCount)
    if vehicle_seats_owners.data[seatNo].eid == eid
      return seatNo
  return -1


def find_seat_no(name: string; seats: ecs::Array) : int
  if name == ""
    return -1

  for seatNo in iter_range(seats)
    let seat = get_ecs_object(seats[seatNo])
    if get_string(seat, "name", "") == name
      return seatNo

  return -1


def vehicle_get_hero_seat_idx(vehicle_seats_owners : VehicleSeatsOwners) : int
  var index = -1
  let hero = get_controlled_hero()
  if hero != ecs::INVALID_ENTITY_ID
    let owners & = vehicle_seats_owners.data
    index = find_index_if(owners) <| $(owner) : bool
      return owner.eid == hero
  return index


[generic]
def is_hero_in_vehicle(vehicle_seats_owners : VehicleSeatsOwners) : bool
  return vehicle_get_hero_seat_idx(vehicle_seats_owners) != -1

[generic]
def is_watched_in_vehicle(vehicle_seats_owners : VehicleSeatsOwners) : bool
  let watched = get_watched_entity()
  if watched == INVALID_ENTITY_ID
    return false
  return find_seat_with_owner(vehicle_seats_owners, watched) != -1

[generic]
def can_place_manually(seatNo: int; orders): bool
  for order in orders
    if order.seatNo == seatNo
      return order.canPlaceManually
  return false
