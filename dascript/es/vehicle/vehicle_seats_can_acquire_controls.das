require ecs
require ecs.common
require vehicle

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_seats_can_acquire_controls_init_es(evt: Event;
                                       [[shared_comp]] vehicle_seats_dot_seats: Array;
                                       [[shared_comp]] vehicle_seats_dot_canAcquireControls: Object;
                                       var vehicle_seats_can_acquire_controls: ecs::IntList)

  resize(vehicle_seats_can_acquire_controls, length(vehicle_seats_dot_seats))

  for seatNo in iter_range(vehicle_seats_can_acquire_controls)
    let seat = get_ecs_object(vehicle_seats_dot_seats[seatNo])
    let controls = get_ecs_object(vehicle_seats_dot_canAcquireControls, get_string(seat, "name", ""))
    if controls != null
      if get_bool(controls, "movement") ?? false
        vehicle_seats_can_acquire_controls[seatNo] |= int(VehicleControlTypes VEHICLE_CONTROLS_MOVEMENT)
      if get_bool(controls, "turrets") ?? false
        vehicle_seats_can_acquire_controls[seatNo] |= int(VehicleControlTypes VEHICLE_CONTROLS_TURRETS)
      if get_bool(controls, "camera") ?? false
        vehicle_seats_can_acquire_controls[seatNo] |= int(VehicleControlTypes VEHICLE_CONTROLS_CAMERA)
