require ecs

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def ballistic_phys_init_es(evt:Event; var ballistic_phys_dot_velocity : float3&; start_vel : float3)
  ballistic_phys_dot_velocity = start_vel

[es(no_order)]
def ballistic_phys_es(info:UpdateStageInfoAct; var transform : float3x4; var ballistic_phys_dot_velocity : float3&)
  let accel = float3(0.0, -9.8065, 0.0)
  transform[3] += ballistic_phys_dot_velocity * info.dt + accel * info.dt * info.dt * 0.5
  ballistic_phys_dot_velocity += accel * info.dt

