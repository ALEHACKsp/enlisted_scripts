require ecs
require math
require DagorMath

[es (tag=gameClient, on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=plane_wreckage)]
def wreckage_phys_init_es(evt: Event;
                          plane_wreckage_dot_mass: float;
                          plane_wreckage_dot_startImpulse: float3;
                          plane_wreckage_dot_startMoment: float3;
                          plane_wreckage_dot_tm: float3x4;
                          var plane_wreckage_dot_vel: float3&;
                          var plane_wreckage_dot_omega: float3&)
  let invMass = 1.0 / plane_wreckage_dot_mass
  plane_wreckage_dot_vel = plane_wreckage_dot_vel + plane_wreckage_dot_startImpulse * invMass
  plane_wreckage_dot_omega = rotate(plane_wreckage_dot_tm, (plane_wreckage_dot_omega + plane_wreckage_dot_startMoment * invMass))

[es (tag=gameClient, REQUIRE=plane_wreckage, no_order)]
def wreckage_phys_es(info: UpdateStageInfoAct;
                     eid: ecs::EntityId;
                     plane_wreckage_dot_offset: float3;
                     plane_wreckage_dot_mass: float;
                     var transform: float3x4;
                     var plane_wreckage_dot_ttl: float&;
                     var plane_wreckage_dot_pos: float3&;
                     var plane_wreckage_dot_orient: float4&;
                     var plane_wreckage_dot_vel: float3&;
                     plane_wreckage_dot_omega: float3)
  let dt = info.dt

  plane_wreckage_dot_ttl -= dt
  if plane_wreckage_dot_ttl <= 0.f
    destroyEntity(eid)
    return

  let invMass = 1.0 / plane_wreckage_dot_mass
  let mass = plane_wreckage_dot_mass

  let acc = invMass * float3(0.0, -9.81f * mass, 0.0)
  plane_wreckage_dot_vel += acc * dt

  plane_wreckage_dot_pos = plane_wreckage_dot_pos + plane_wreckage_dot_vel * dt

  let orientInc = plane_wreckage_dot_omega * dt
  let quatInc   = quat(orientInc, length(orientInc))
  plane_wreckage_dot_orient = float4(normalize(quat(plane_wreckage_dot_orient) * quatInc))

  var offsetTm: float3x4
  identity(offsetTm)
  offsetTm[3] = plane_wreckage_dot_offset

  var wreckageTm: float3x4
  make_tm(quat(plane_wreckage_dot_orient), plane_wreckage_dot_pos, wreckageTm)
  transform = wreckageTm * offsetTm
