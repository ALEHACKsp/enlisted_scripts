require ecs
require vehicle

[es(tag=sound, track=isInVehicle)]
def plane_fall_sound_disabler(evt : Event; human_anim_dot_vehicleSelected, vehicle_dot_lastEid : EntityId;
                              isInVehicle : bool; var human_fall_sound_dot_enabled : bool&)
  if isInVehicle && has(human_anim_dot_vehicleSelected, "airplane")
    human_fall_sound_dot_enabled = false
  elif !isInVehicle && has(vehicle_dot_lastEid, "airplane")
    human_fall_sound_dot_enabled = true