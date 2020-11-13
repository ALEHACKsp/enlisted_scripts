require ecs

[es (tag=render, on_event=(EventEntityCreated,EventComponentsAppear), track=human_anim_dot_vehicleSelected)]
def vehicle_seats_disable_ragdoll(evt : Event; human_anim_dot_vehicleSelected : EntityId; var ragdoll_dot_isAllowed : bool&)
  ragdoll_dot_isAllowed = !has(human_anim_dot_vehicleSelected, "vehicle_seats.disableRagdoll")