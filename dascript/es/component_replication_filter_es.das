require ecs
require net

var
  filterPossessed:uint8
  filterPossessedAndSpectated:uint8
  filterPossessedSquadOrSpectatedSquad:uint8
  filterPossessedSpectatedAndAttachables:uint8
  filterPossessedVehicle:uint8
  filterPossessedAndSpectatedVehicle:uint8
  filterPossessedSpectatedAttachablesAndVehicle:uint8

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=msg_sink)]
def filter_creation_track(evt: Event)
  filterPossessed = find_component_filter("filter_possessed")
  filterPossessedAndSpectated = find_component_filter("filter_possessed_and_spectated")
  filterPossessedSquadOrSpectatedSquad = find_component_filter("filter_possessed_squad_and_spectated_squad")
  filterPossessedSpectatedAndAttachables = find_component_filter("filter_possessed_spectated_and_attachables")
  filterPossessedSpectatedAttachablesAndVehicle = find_component_filter("filter_possessed_spectated_attachables_and_vehicle")
  filterPossessedVehicle = find_component_filter("filter_possessed_vehicle")
  filterPossessedAndSpectatedVehicle = find_component_filter("filter_possessed_and_spectated_vehicle")

[es (tag=server, track=possessed, REQUIRE=possessed)]
def on_change_possesed_es(evt: Event)
  update_component_filter_event(filterPossessed)
  update_component_filter_event(filterPossessedAndSpectated)
  update_component_filter_event(filterPossessedSquadOrSpectatedSquad)
  update_component_filter_event(filterPossessedSpectatedAndAttachables)
  update_component_filter_event(filterPossessedSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedAndSpectatedVehicle)

[es (tag=server, track=specTarget, REQUIRE=specTarget)]
def on_change_spectator_target_es(evt: Event)
  update_component_filter_event(filterPossessedAndSpectated)
  update_component_filter_event(filterPossessedSquadOrSpectatedSquad)
  update_component_filter_event(filterPossessedSpectatedAndAttachables)
  update_component_filter_event(filterPossessedSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedAndSpectatedVehicle)

[es (tag=server, track=human_anim_dot_vehicleSelected, REQUIRE=human_anim_dot_vehicleSelected)]
def on_change_vehicle_selected_es(evt: Event)
  update_component_filter_event(filterPossessedVehicle)
  update_component_filter_event(filterPossessedSpectatedAttachablesAndVehicle)
  update_component_filter_event(filterPossessedAndSpectatedVehicle)
