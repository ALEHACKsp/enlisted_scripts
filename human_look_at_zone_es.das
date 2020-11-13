require ecs
require math
require math.linear

[es (tag=gameClient, REQUIRE=human_input, no_order)]
def human_look_at_zone_es(act : ecs::UpdateStageInfoAct; isAlive : bool;
                          human_dot_aimTm : float3x4; var human_dot_lookAtZone : EntityId&;
                          human_dot_lookAtZoneMinDot : float = 0.97; human_dot_lookAtZoneMinDistance : float = 5.0)
  if !isAlive
    return
  let lookPos = human_dot_aimTm[3]
  let lookDir = human_dot_aimTm[0]
  var bestScore = 0.0
  var bestZone = INVALID_ENTITY_ID
  ecs::query() <| $ [es(REQUIRE=capzone)](eid : EntityId; active : bool; transform : float3x4)
    if !active
      return
    let dir = normalize(transform[3] - lookPos)
    let lookDot = dot(dir, lookDir)
    let distanceToRay = distance_to_line(transform[3], lookPos, lookDir)
    if lookDot < human_dot_lookAtZoneMinDot || distanceToRay > human_dot_lookAtZoneMinDistance
      return
    let ratio = (1.0 - lookDot) * distance_sq(transform[3], lookPos) + (1.0 - lookDot) * distanceToRay
    if ratio < bestScore || bestZone == INVALID_ENTITY_ID
      bestScore = ratio
      bestZone = eid
  human_dot_lookAtZone = bestZone
