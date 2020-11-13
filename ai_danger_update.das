require ecs
require walkerai
require game.utils.team
require math
require math.base
require EnlistedWalkerai
require DagorRandom
require DagorMath
require Dacoll
require RendInst
require CollRes
require AnimV20
require GridCollision
require game.es.ai.ai_danger_common
require SmokeOccluder

struct TargetData
  eid : EntityId
  team : int
  isAlive : bool
  isHidden : bool
  targetPos : float3

def TargetData(eid : EntityId; team : int; target : Target)
  return [[TargetData eid = eid, team = team, isAlive = target.isAlive, isHidden = target.isHidden, targetPos = target.targetPos]]

def find_danger(var agent_dangers : AgentDangers; eid : EntityId)
  for i in iter_range(agent_dangers.dangers)
    if agent_dangers.dangers[i].eid == eid
      return i
  return -1

[es(tag=server, no_order)]
def ai_danger_update_alertness(act:UpdateStageInfoAct)
  var targets : array<TargetData>
  query() <| $[es(REQUIRE_NOT=ai_target_dot_autoGunTarget)](eid : EntityId; ai_target : Target; team : int)
    var targetData = TargetData(eid, team, ai_target)
    targets |> emplace(targetData)

  query() <| $[es(REQUIRE=agent_dangers_dot_proceduralDangerMeter)](isAlive : bool; team : int; beh_tree_dot_enabled : bool = true;
                  walker_agent : EntityAgent; var agent_dangers : AgentDangers;
                  agent_dangers_dot_maxDangerDist : float;
                  var agent_dangers_dot_nextDangersCheckTime : float&;
                  alertness_calc_dot_distCoef : float2;
                  alertness_calc_dot_frustumCoef : float3;
                  alertness_calc_dot_frustumOffset : float2;
                  agent_dangers_dot_checkTimes = float2(0.3, 0.7);
                  agent_dangers_dot_frustumAngle = 40.; agent_dangers_dot_blindDistance = 200.)

    if !isAlive || !beh_tree_dot_enabled
      clear(agent_dangers.dangers)
      return
    if act.curTime < agent_dangers_dot_nextDangersCheckTime
      return

    agent_dangers_dot_nextDangersCheckTime = act.curTime + rnd_float(agent_dangers_dot_checkTimes.x, agent_dangers_dot_checkTimes.y);

    let fromPos = get_walker_agent_shoot_from_pos(walker_agent, 2)
    let frustumMinCos = cos(deg_to_rad(agent_dangers_dot_frustumAngle))
    let shootDir = walker_agent.shootDir

    for target in targets
      let dangerIdx = find_danger(agent_dangers, target.eid)
      if !target.isAlive || target.isHidden || is_teams_friendly(team, target.team)
        if dangerIdx >= 0
          erase(agent_dangers.dangers, dangerIdx)
        continue

      let targetDir = target.targetPos - fromPos
      let dist = length(targetDir)
      if dist > agent_dangers_dot_blindDistance
        if dangerIdx >= 0
          erase(agent_dangers.dangers, dangerIdx)
        continue

      let frustumCos = dot(normalize(targetDir), shootDir)
      let inFrustum = frustumCos >= frustumMinCos
      let alertness = calc_target_alertness(dist, frustumCos, agent_dangers_dot_maxDangerDist, alertness_calc_dot_distCoef,
                                            alertness_calc_dot_frustumCoef, alertness_calc_dot_frustumOffset)
      if alertness <= 0.0
        if dangerIdx >= 0
          erase(agent_dangers.dangers, dangerIdx)
      else
        if dangerIdx >= 0
          var danger & = agent_dangers.dangers[dangerIdx]
          danger.distance = dist
          danger.alertness = alertness
          if !inFrustum
            danger.inFrustumTime = -1f
          elif danger.inFrustumTime < 0f
            danger.inFrustumTime = act.curTime
        else
          var newDanger : Danger
          newDanger.eid = target.eid
          newDanger.dangerType = DangerType EDT_DESTROY
          newDanger.inFrustumTime = inFrustum ? act.curTime : -1.
          newDanger.distance = dist
          newDanger.alertness = alertness
          newDanger.lastTraceTime = -1.
          newDanger.lastBulletNearbyTime = -1.
          newDanger.traceable = false
          newDanger.dangerMeter = 0f
          push_back(agent_dangers.dangers, newDanger)


[es(tag=server, after=ai_danger_update_traceable, REQUIRE=agent_dangers_dot_proceduralDangerMeter)]
def ai_danger_trace_targets(act:UpdateStageInfoAct; eid : EntityId; isAlive : bool;
                            var agent_dangers : AgentDangers; walker_agent : EntityAgent;
                            beh_tree_dot_enabled : bool = true;
                            var agent_dangers_dot_nextDangersTraceTime : float&;
                            danger_calc_dot_aiCoef: float2;
                            danger_calc_dot_downedCoef: float2;
                            danger_calc_dot_avoidBulletsNearTime:float;
                            danger_calc_dot_distanceCoef: float3;
                            danger_calc_dot_inFrustumCoef: float3;
                            danger_calc_dot_lastShootCoef: float2;
                            danger_calc_dot_lastKillCoef: float2;
                            danger_calc_dot_noiseCoef: float2;
                            danger_calc_dot_lastBulletNearbyCoef: float2;
                            agent_dangers_dot_nextDangersTraceCheckTime : float = 0.1f;
                            var human_stat_tracking_dot_targetTracesCount : int?;
                            agent_dangers_dot_maxDangerDist : float = 100f;
                            agent_dangers_dot_gridTraceDistAdd : float = 3f;
                            agent_dangers_calc_dot_dangerMeterMult : float = 1f;
                            agent_dangers_dot_hmapTraceOffset : float3 = float3(0., 0., 0.);
                            var human_stat_tracking_dot_totalDangers : float?)
  if !isAlive || !beh_tree_dot_enabled || length(agent_dangers.dangers) == 0 || act.curTime < agent_dangers_dot_nextDangersTraceTime
    return

  agent_dangers_dot_nextDangersTraceTime = act.curTime + agent_dangers_dot_nextDangersTraceCheckTime

  let agentEid = eid
  let fromPos = get_walker_agent_shoot_from_pos(walker_agent, 2)
  let flags = (ETF_ALL) & ~(ETF_LMESH | ETF_HEIGHTMAP)
  var maxRatio = 0f
  var traceTo = INVALID_ENTITY_ID

  var targets : array<tuple<Target const?; float>>
  reserve(targets, length(agent_dangers.dangers))
  for danger in agent_dangers.dangers
    var found = false
    query(danger.eid) <| $[es](ai_target : Target; beh_tree_dot_enabled : bool = false)
      found = true
      let potentialDangerMeter = calc_danger(act.curTime, agent_dangers_dot_maxDangerDist, danger, ai_target, beh_tree_dot_enabled,
                                             danger_calc_dot_aiCoef, danger_calc_dot_downedCoef, danger_calc_dot_avoidBulletsNearTime,
                                             danger_calc_dot_distanceCoef, danger_calc_dot_inFrustumCoef,
                                             danger_calc_dot_lastShootCoef, danger_calc_dot_lastKillCoef,
                                             danger_calc_dot_noiseCoef, danger_calc_dot_lastBulletNearbyCoef)
      unsafe
        targets |> emplace([[auto addr(ai_target), potentialDangerMeter]])
      let ratio = calc_traceable_ratio(act.curTime, potentialDangerMeter, danger)
      if ratio > maxRatio
        maxRatio = ratio
        traceTo = danger.eid
    if !found
      var empty : tuple<Target const?; float>
      targets |> emplace(empty)

  for i in iter_range(agent_dangers.dangers)
    var danger & = agent_dangers.dangers[i]
    var ai_target = targets[i]._first
    var potentialDangerMeter = targets[i]._last
    if ai_target == null || !ai_target.isAlive || ai_target.isHidden
      danger.dangerMeter = 0f
      continue
    if maxRatio >= 3.7f && danger.eid == traceTo
      danger.lastTraceTime = act.curTime
      let dir = normalize(ai_target.targetPos - fromPos)
      let lmeshTracePos = fromPos + agent_dangers_dot_hmapTraceOffset
      if human_stat_tracking_dot_targetTracesCount != null
        (*human_stat_tracking_dot_targetTracesCount)++
      var collides = (rayhit_normalized_lmesh(lmeshTracePos, dir, danger.distance) ||
                      rayhit_normalized(fromPos, dir, danger.distance, flags, walker_agent.shootRayMat) ||
                      traceTransparencyRayRIGenNormalized(fromPos, dir, danger.distance, 0.01) ||
                      rayhit_smoke_occluders(fromPos, ai_target.targetPos))
      if !collides
        var box : BBox3
        var t = length(ai_target.targetPos - fromPos)
        var norm : float3
        box |> bbox3_add(fromPos)
        box |> bbox3_add(fromPos + dir * t)
        find_object_in_grid(GridType GT_DEFAULT, box) <| $(it:TraceableGridCollision #)
          if it.eid != danger.eid && it.eid != agentEid && uint(it.eid) != ai_target.useVehicle && distance_sq(it.pos, fromPos) < danger.distance + agent_dangers_dot_gridTraceDistAdd
            query(it.eid) <| $ [es] (transform : float3x4; collres: CollisionResource; animchar: AnimcharBaseComponent)
              collides = collres_traceray(collres, transform, animchar, fromPos, dir, t, norm) && t < danger.distance
          return collides
      danger.traceable = !collides

    danger.dangerMeter = danger.traceable ? potentialDangerMeter : 0.
    danger.dangerMeter *= agent_dangers_calc_dot_dangerMeterMult

    danger.noiseMeter = calc_noise(act.curTime, agent_dangers_dot_maxDangerDist, danger, *ai_target,
                                  danger_calc_dot_avoidBulletsNearTime,
                                  danger_calc_dot_distanceCoef,
                                  danger_calc_dot_lastShootCoef, danger_calc_dot_lastKillCoef,
                                  danger_calc_dot_noiseCoef, danger_calc_dot_lastBulletNearbyCoef)

    if human_stat_tracking_dot_totalDangers != null
      *human_stat_tracking_dot_totalDangers += float(length(agent_dangers.dangers)) * agent_dangers_dot_nextDangersTraceCheckTime
