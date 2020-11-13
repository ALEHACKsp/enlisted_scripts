require ecs
require PhysVars
require AnimV20
require EnlistedDeviceAnim
require DagorSystem

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def init_device_anim_vars(evt : Event;
                          var phys_vars : PhysVars;
                          var device_anim_dot_stateVarId : int&;
                          var device_anim_dot_progressVarId : int&;
                          var device_anim_dot_states : ecs::IntList)
  device_anim_dot_stateVarId = register_var(phys_vars, "device_state", 0.f);
  device_anim_dot_progressVarId = register_var(phys_vars, "device_progress", 0.f);

  var stateNo = 0
  if length(device_anim_dot_states) < 5
    logerr("Wrong length of device_anim_dot_states: {length(device_anim_dot_states)}. Should be at least 5.")
    return
  for anim_state in [[string[5] "device_disabled"; "device_prepare"; "device_use"; "device_fire"; "device_post"]]
    device_anim_dot_states[stateNo++] = animV20_get_enum_value_by_name(anim_state)

[es (tag=render, on_event=(EventEntityCreated, EventComponentsAppear))]
def device_anim_fpv_init(evt: Event; var device_anim_dot_isFpvVarId: int&; var phys_vars: PhysVars)
  device_anim_dot_isFpvVarId = register_var(phys_vars, "is_fpv", 0.0)