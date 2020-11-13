require ecs

[es (track=(isInVehicle,locked_dot_pickupItemsLockedByAffect,human_weap_dot_radioMode,human_weap_dot_mortarMode))]
def can_pickup_items_conditions(evt: Event;
                                var human_dot_canPickupItems : bool&;
                                isInVehicle : bool = false;
                                locked_dot_pickupItemsLockedByAffect : bool = false;
                                human_weap_dot_radioMode : bool = false;
                                human_weap_dot_mortarMode : bool = false)
  human_dot_canPickupItems = (!isInVehicle &&
                              !locked_dot_pickupItemsLockedByAffect &&
                              !human_weap_dot_radioMode &&
                              !human_weap_dot_mortarMode)