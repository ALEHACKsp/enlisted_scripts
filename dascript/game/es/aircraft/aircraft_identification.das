require ecs
require math.base

[es (tag=gameClient, no_order, REQUIRE=watchedByPlr)]
def aircraft_identification(info: UpdateStageInfoAct;
                            var aircraft_identification_dot_nextCheckAtTime : float&;
                            aircraft_identification_dot_checkInterval : float;
                            transform : float3x4;
                            camera_dot_lookDir : float3;
                            aircraft_identification_dot_detectDistance : float;
                            aircraft_identification_dot_identifyDistance : float;
                            aircraft_identification_dot_peripheryDistMult : float;
                            aircraft_identification_dot_peripheryToCenterAngleDeg : float)
  if info.curTime < aircraft_identification_dot_nextCheckAtTime
    return
  aircraft_identification_dot_nextCheckAtTime = info.curTime + aircraft_identification_dot_checkInterval

  let heroPos& = transform[3]
  let lookDir = normalize(camera_dot_lookDir)
  let focusedIdentifyDist = aircraft_identification_dot_identifyDistance
  let peripheryIdentifyDist = aircraft_identification_dot_identifyDistance * aircraft_identification_dot_peripheryDistMult
  let focusedDetectDist = aircraft_identification_dot_detectDistance
  let peripheryDetectDist = aircraft_identification_dot_detectDistance * aircraft_identification_dot_peripheryDistMult
  let peripheryAngleCos = cos(clamp(deg_to_rad(aircraft_identification_dot_peripheryToCenterAngleDeg), 0.0, PI))

  query() <| $[es (REQUIRE=airplane)] (transform : float3x4;
                                       var hud_aircraft_marker_dot_isIdentified : bool&;
                                       var hud_aircraft_marker_dot_isVisible : bool&)
    var dirToAirplane = transform[3] - heroPos
    let distance = length(dirToAirplane)
    dirToAirplane *= safeinv(distance)
    let isOnPeriphery = dot(lookDir, dirToAirplane) < peripheryAngleCos
    let identifyDist = isOnPeriphery ? peripheryIdentifyDist : focusedIdentifyDist
    let detectDist = isOnPeriphery ? peripheryDetectDist : focusedDetectDist

    hud_aircraft_marker_dot_isVisible = distance < detectDist
    hud_aircraft_marker_dot_isIdentified = distance < identifyDist
