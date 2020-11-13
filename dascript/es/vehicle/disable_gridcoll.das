require ecs

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=isInVehicleHidden)]
def gridcoll_set_in_vehicle_es(evt: Event;
                               isInVehicleHidden: bool;
                               var gridcoll_dot_enabled: bool&)
  gridcoll_dot_enabled = !isInVehicleHidden
