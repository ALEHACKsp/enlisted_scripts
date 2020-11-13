require ecs
require game.es.events
require pathfinder

[es (tag=server, REQUIRE=vehicleSpawnValidation, on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_spawn_validate(evt : Event;
                           eid : EntityId;
                           transform : float3x4;
                           spawn_validation_dot_spreadDistance : float;
                           spawn_validation_dot_useNavmesh : bool = false)
  let createdVehicleEid = eid
  var wishPos = transform[3]

  var vehiclesPos : array<float3>
  query() <| $ [es (REQUIRE=vehicle)] (eid : EntityId; transform : float3x4)
    if eid == createdVehicleEid
      return
    push(vehiclesPos, transform[3])

  var shouldTeleport = false

  for i in range(0, 6)
    var isWorking = false
    for pos in vehiclesPos
      var dist = wishPos - pos
      dist.y = 0.0
      var len = length(dist)
      if len == 0.0
        len = 1.0
        dist = float3(1.0, 0.0, 0.0)
      if len < spawn_validation_dot_spreadDistance
        dist = dist * (1.0 / len)
        wishPos = wishPos + dist * ((spawn_validation_dot_spreadDistance - len) + 1.)
        shouldTeleport = true
        isWorking = true
    if !isWorking
      break

  if shouldTeleport
    if spawn_validation_dot_useNavmesh
      project_to_nearest_navmesh_point(wishPos, spawn_validation_dot_spreadDistance)
    var wishTm = transform
    wishTm[3] = wishPos
    sendEventImmediate(createdVehicleEid, [[CmdTeleportEntity newTm=wishTm, hard=false]])
