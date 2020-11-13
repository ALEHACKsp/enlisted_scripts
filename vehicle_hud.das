require ecs
require vehicle
require math
require DagorMath

let
  MSEC_TO_KMH = 3.6f

[es (tag=gameClient, no_order, REQUIRE=heroVehicle)]
def vehicle_hud(info: UpdateStageInfoAct;
                vehicle_net_phys: VehiclePhysActor;
                transform: float3x4;
                var vehicle_dot_gear: int&;
                var vehicle_dot_neutralGear: int&;
                var vehicle_dot_rpm: int&;
                var vehicle_dot_cruiseControl: int&;
                var vehicle_dot_speed: int&)
  vehicle_dot_gear = int(vehicle_net_phys.phys.currentState.currentGear)
  vehicle_dot_neutralGear = int(vehicle_net_phys.phys.neutralGearIndex)

  let rpm = roundi(vehicle_net_phys.phys.currentState.engineOmega * 60.f / (2.f * PI))
  vehicle_dot_rpm = rpm - rpm % 100

  let speed = dot(float3(vehicle_net_phys.phys.currentState.velocity), transform[0])
  vehicle_dot_speed = roundi(speed * MSEC_TO_KMH)

  vehicle_dot_cruiseControl = int(vehicle_net_phys.phys.currentState.cruiseControl)