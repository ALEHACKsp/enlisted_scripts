require ecs
require ecs.common
require game.es.vehicle.vehicle_seats_common

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_seats_sext_seats_init_es(evt: Event;
                                     [[shared_comp]] vehicle_seats_dot_seats: Array;
                                     var vehicle_seats_next_seats: ecs::IntList)
  resize(vehicle_seats_next_seats, length(vehicle_seats_dot_seats))

  for seatNo in iter_range(vehicle_seats_next_seats)
    let seat = get_ecs_object(vehicle_seats_dot_seats[seatNo])
    vehicle_seats_next_seats[seatNo] = find_seat_no(get_string(seat, "nextSeat", ""), vehicle_seats_dot_seats)
