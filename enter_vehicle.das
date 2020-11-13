require ecs
require app
require math
require math.base
require EnlistedHuman


[es (track=enter_vehicle_dot_atTime)]
def enter_vehicle_start_timer(evt : Event;
                              enter_vehicle_dot_atTime : float;
                              var enter_vehicle_dot_isInitDataSaved : bool&)
  if enter_vehicle_dot_atTime >= 0.0
    enter_vehicle_dot_isInitDataSaved = false

[es (tag=gameClient, track=enter_vehicle_dot_atTime)]
def enter_vehicle_init_restrictions_client(evt : Event;
                                           transform : float3x4;
                                           human_net_phys : HumanActor;
                                           enter_vehicle_dot_atTime: float;
                                           var enter_vehicle_dot_initPos : float3&;
                                           var enter_vehicle_dot_initGunDir : float3&)
  if enter_vehicle_dot_atTime < 0.0
    return
  enter_vehicle_dot_initPos = transform[3]
  enter_vehicle_dot_initGunDir = human_net_phys.phys.appliedCT.wishShootDir

[es (tag=server, on_event=CmdPostPhysUpdate)]
def enter_vehicle_init_restrictions(evt : Event;
                                    transform : float3x4;
                                    human_net_phys : HumanActor;
                                    enter_vehicle_dot_atTime : float;
                                    enter_vehicle_dot_vehicleEid : EntityId;
                                    var enter_vehicle_dot_initPos : float3&;
                                    var enter_vehicle_dot_initGunDir : float3&;
                                    var enter_vehicle_dot_initVehiclePos : float3&;
                                    var enter_vehicle_dot_isInitDataSaved : bool&)
  if enter_vehicle_dot_atTime < 0.0 || enter_vehicle_dot_isInitDataSaved
    return
  enter_vehicle_dot_initPos = transform[3]
  enter_vehicle_dot_initGunDir = human_net_phys.phys.appliedCT.wishShootDir
  query(enter_vehicle_dot_vehicleEid) <| $ [es] (transform : float3x4)
    enter_vehicle_dot_initVehiclePos = transform[3]
  enter_vehicle_dot_isInitDataSaved = true

[es (on_event=CmdPostPhysUpdate)]
def enter_vehicle_interrupt(evt : Event;
                            transform : float3x4;
                            human_net_phys : HumanActor;
                            enter_vehicle_dot_moveThreshold : float;
                            enter_vehicle_dot_gunMoveAngleThreshold : float;
                            enter_vehicle_dot_initPos : float3;
                            enter_vehicle_dot_initGunDir : float3;
                            var enter_vehicle_dot_atTime : float&;
                            enter_vehicle_dot_isInitDataSaved : bool = true)
  if enter_vehicle_dot_atTime < 0.0 || !enter_vehicle_dot_isInitDataSaved
    return

  let moveThresSq = enter_vehicle_dot_moveThreshold * enter_vehicle_dot_moveThreshold
  if distance_sq(enter_vehicle_dot_initPos, transform[3]) > moveThresSq
    enter_vehicle_dot_atTime = -1.0
    return

  let gunDir = human_net_phys.phys.appliedCT.wishShootDir
  let angleThres = deg_to_rad(enter_vehicle_dot_gunMoveAngleThreshold)
  let dotval = clamp(dot(enter_vehicle_dot_initGunDir, gunDir), -1.0, 1.0)
  if dotval < cos(angleThres)
    enter_vehicle_dot_atTime = -1.0

[es (tag=server, on_event=CmdPostPhysUpdate)]
def enter_vehicle_interrupt_vehicle_moved(evt : Event;
                                          var enter_vehicle_dot_atTime : float&;
                                          enter_vehicle_dot_vehicleEid : EntityId;
                                          enter_vehicle_dot_initVehiclePos : float3;
                                          enter_vehicle_dot_vehicleMoveThreshold : float)
  if enter_vehicle_dot_atTime < 0.0
    return
  query(enter_vehicle_dot_vehicleEid) <| $ [es] (transform : float3x4)
    let vehicleMoveThresSq = enter_vehicle_dot_vehicleMoveThreshold * enter_vehicle_dot_vehicleMoveThreshold
    if distance_sq(enter_vehicle_dot_initVehiclePos, transform[3]) > vehicleMoveThresSq
      enter_vehicle_dot_atTime = -1.0
