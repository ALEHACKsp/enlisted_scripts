options remove_unused_symbols = false
module turrets_common
require ecs
require ecs.common

def find_turret_index_by_name(turret_control_dot_turretInfo: Array; turret_name : string) : int
  if turret_name == ""
    return -1
  return find_index_if(turret_control_dot_turretInfo) <| $ (elem) : bool
    return get_string(get_ecs_object(elem), "turretName", "") == turret_name