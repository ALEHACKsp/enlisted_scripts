options always_export_initializer=true
require ecs
require net
require game.es.events
require game.es.ai.walker_common
require game.es.ai.walker_node
require DagorDataBlock
require DagorMath
require Dacoll
require RendInst
require SmokeOccluder
require GridCollision
require BehNodes
require EnlistedBehNodes
require app
require math
require math.base
require HumanPhys
require EnlistedHuman
require EnlistedWalkerai
require DagorSystem
require DagorRandom
require game.utils.team
require game.es.concussion_common
require DagorConsole
require game.es.squad_common
require pathfinder
require zones
require game.es.battle_area_common

[init] def registerNodes()
  init_beh_nodes()

[beh_node(name="chooseMaxStance")]
class ChooseMaxStanceNode : BehNodeAdapter
  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    agent.blackBoard |> get_or_create("maxStance", STANCE_STAND)
    agent.blackBoard |> get_or_create("maxStanceOrder", STANCE_STAND)
    agent.blackBoard |> get_or_create("maxStanceOrderEndTime", 0f)
    agent.blackBoard |> get_or_create("maxStanceInternal", STANCE_STAND)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    let maxStanceInternal = agent.blackBoard |> datablock_getInt("maxStanceInternal", STANCE_STAND)
    var maxStanceOrder = agent.blackBoard |> datablock_getInt("maxStanceOrder", STANCE_STAND)
    var resetOder = false
    if maxStanceOrder < STANCE_STAND
      let maxStanceOrderEndTime = agent.blackBoard |> datablock_getReal("maxStanceOrderEndTime", 0f)
      if maxStanceOrderEndTime < get_sync_time()
        resetOder = true
      elif (get_int(agent.eid, "walker_agent.serverAiAction") ?? int(AiAction AI_ACTION_UNKNOWN)) == int(AiAction AI_ACTION_MOVE)
        resetOder = true

    if resetOder
      maxStanceOrder = STANCE_STAND
      agent.blackBoard |> datablock_setInt("maxStanceOrder", maxStanceOrder)

    agent.blackBoard |> datablock_setInt("maxStance", min(maxStanceInternal, maxStanceOrder))
    return EBehResult ER_SUCCESS

[private]
def determinate_radius(phys_state : HumanPhysState)
  return determinate_stance(phys_state) == STANCE_CRAWL ? 0.7 : 0.5

[beh_node(name="validateStandPosition")]
class ValidateStandPositionNode : BehNodeAdapter
  movingTime : float = 0f
  maxMovingTime = 2f
  resetWishPositionThreshold = 1f
  wishPosParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    wishPosParam = agent.blackBoard |> get_or_create("wishPosition", agent.pos)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_SUCCESS
    var phys = agent.phys
    if phys == null
      return EBehResult ER_SUCCESS
    var collides = 0
    var moveDir : float3
    if movingTime < maxMovingTime
      let agentRadius = determinate_radius(phys.currentState)
      for_each_object_in_grid(GridType GT_DEFAULT, BBox3(agent.pos, agentRadius + 2f)) <| $(it:TraceableGridCollision#)
        if it.eid != agent.eid && collides <= 2
          ecs::query(it.eid) <| $ [es] (isAlive : bool; human_net_phys : HumanActor)
            if isAlive
              let radius = determinate_radius(human_net_phys.phys.currentState)
              if distance_sq(agent.pos, it.pos) <= square(radius + agentRadius)
                let dir = normalize(agent.pos - it.pos)
                moveDir += dir
                collides ++
    let walkDir = moveDir.xz
    if collides >= 1 && collides <= 2 && length(walkDir) > FLT_EPSILON
      phys.producedCT |> human_control_state_set_walk_dir(normalize(walkDir))
      phys.producedCT |> human_control_state_set_walk_speed(0.5)
      movingTime += dt
    elif movingTime > 0f
      let wishPos = agent.blackBoard |> datablock_getPoint3(wishPosParam)
      if distance_sq(wishPos, agent.pos) < resetWishPositionThreshold
        agent.blackBoard |> datablock_setPoint3(wishPosParam, agent.pos)
      phys.producedCT |> human_control_state_set_walk_speed(0f)
      movingTime = 0f

    return movingTime > 0f ? EBehResult ER_RUNNING : EBehResult ER_SUCCESS


[beh_node(name="setEnemyMark")]
class SetEnemyMark : BehNodeAdapter
  maxTraceCount = 1
  targetDistSearch = 40f
  minTargetAngleCos = 0.95

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_SUCCESS
    let playerEid = get_Eid(agent.eid, "possessedByPlr") ?? INVALID_ENTITY_ID
    let aimTMRef = get_TMatrix(agent.eid, "human.aimTm")
    if !playerEid || aimTMRef == null
      return EBehResult ER_SUCCESS
    let aimTm = *aimTMRef
    let tracePos = aimTm[3]
    let traceDir = aimTm[0]
    let flags = (ETF_ALL) & ~(ETF_LMESH | ETF_HEIGHTMAP)
    var tracesCount = 0
    var box : BBox3
    box |> bbox3_add(tracePos)
    box |> bbox3_add(tracePos + traceDir * targetDistSearch)
    find_object_in_grid(GridType GT_DEFAULT, box) <| $(it:TraceableGridCollision#)
      query(it.eid) <| $[es](team : int)
        if is_teams_friendly(team, agent.teamId) || team == TEAM_UNASSIGNED
          return
        let targetPos = it.pos
        var dir = targetPos - tracePos
        var dist = length(targetPos - tracePos)
        dir *= safeinv(dist)
        if dot(dir, traceDir) < minTargetAngleCos
          return
        tracesCount++
        if (rayhit_normalized(tracePos, dir, dist, flags, agent.shootRayMat) ||
                        traceTransparencyRayRIGenNormalized(tracePos, dir, dist, 0.01) ||
                        rayhit_smoke_occluders(tracePos, targetPos))
          return
        sendEvent(playerEid, [[CmdCreateMapUserPoint pos = it.pos, item_name = "enemy" ]])
        tracesCount = maxTraceCount // one event per update is enough
      return tracesCount < maxTraceCount

    return EBehResult ER_SUCCESS


[beh_node(name="isInConcussion")]
class IsInConcussion : BehNodeAdapter
  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED
    let isConcussion = has_concussion_affect(agent.eid)
    return isConcussion ? EBehResult ER_SUCCESS : EBehResult ER_FAILED


[beh_node(name="inConcussion")]
class InConcussion : BehNodeAdapter
  isStarted : bool = false
  def override init()
    isStarted = false

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED
    let has_concussion = has_concussion_affect(agent.eid)
    if !has_concussion
      return isStarted ? EBehResult ER_SUCCESS : EBehResult ER_FAILED
    var phys = agent.phys
    if phys == null
      return EBehResult ER_FAILED
    if !isStarted
      isStarted = true
      phys.producedCT |> human_control_state_set_walk_speed(0f)
      phys.producedCT |> human_control_state_reset()
    return EBehResult ER_RUNNING



[beh_node(name="inAiMode")]
class InAiMode : BehNodeAdapter
  targetAiMode : int = int(AiMode AI_OFFENSIVE)
  aiModeParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    aiModeParam = agent.blackBoard |> get_or_create("aiMode", int(AiMode AI_OFFENSIVE))

    let aiModeName = datablock_getStr(data, "aiMode", "unknown")
    if aiModeName == "offensive"
      targetAiMode = int(AiMode AI_OFFENSIVE)
    elif aiModeName == "defensive"
      targetAiMode = int(AiMode AI_DEFENSIVE)
    else
      logerr("unknown ai mode {aiModeName} in InAiMode node")


  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if targetAiMode == int(AiMode AI_UNKNOWN) || agent == null
      return EBehResult ER_FAILED

    let currentAiMode = agent.blackBoard |> datablock_getInt(aiModeParam)
    return currentAiMode == targetAiMode ? EBehResult ER_SUCCESS : EBehResult ER_FAILED

[beh_node(name="selectAIMode")]
class SelectAIMode : BehNodeAdapter
  aiModeParam : int = -1
  squadEid : ecs::EntityId = ecs::INVALID_ENTITY_ID
  defendDistTresholdSq : float = 1f
  criticalDistToLeaderSq : float = 1f

  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    squadEid = get_Eid(agent.eid, "squad_member.squad") ?? ecs::INVALID_ENTITY_ID
    defendDistTresholdSq = square(data |> datablock_getReal("defendDistTreshold", 8f))
    criticalDistToLeaderSq = square(data |> datablock_getReal("criticalDistToLeader", 20f))

    aiModeParam = agent.blackBoard |> get_or_create("aiMode", int(AiMode AI_OFFENSIVE))

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    let prevBehaviour : int = agent.blackBoard |> datablock_getInt(aiModeParam)
    var nextBehaviour : int = prevBehaviour

    query(squadEid) <| $[es](squad_dot_leader : ecs::EntityId; squad_dot_orderType : int; squad_dot_regroupPos : float3; squad_dot_AIMode : int)
      if squad_dot_leader == agent.eid
        nextBehaviour = int(AiMode AI_OFFENSIVE)
        return

      if squad_dot_orderType == int(SquadOrder ESO_ATTACK_TARGET) || squad_dot_orderType == int(SquadOrder ESO_USE_VEHICLE)
        nextBehaviour = int(AiMode AI_OFFENSIVE)
        return
      if squad_dot_orderType == int(SquadOrder ESO_DEFEND_POINT)
        let distSq = length_sq(agent.pos - squad_dot_regroupPos)
        nextBehaviour = distSq > defendDistTresholdSq ? int(AiMode AI_OFFENSIVE) : int(AiMode AI_DEFENSIVE)
        return
      if squad_dot_orderType == int(SquadOrder ESO_FOLLOW_ME)
        query(squad_dot_leader) <| $[es](transform : float3x4)
          let distSq = length_sq(agent.pos - transform[3])
          if distSq > criticalDistToLeaderSq
            nextBehaviour = int(AiMode AI_OFFENSIVE)
            return
          nextBehaviour = squad_dot_AIMode

    if prevBehaviour == nextBehaviour
      return EBehResult ER_FAILED
    agent.blackBoard |> datablock_setInt(aiModeParam, nextBehaviour)
    return EBehResult ER_SUCCESS

[beh_node(name="deactivateWeapMod")]
class DeactivateWeapModNode : BehNodeAdapter
  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_SUCCESS
    ecs::query(agent.eid) <| $ [es] (human_weap_dot_currentGunSlot : int; human_weap_dot_gunMods : ecs::EidList)
      if human_weap_dot_currentGunSlot < 0
        return
      let curGunMod = human_weap_dot_gunMods[human_weap_dot_currentGunSlot]
      ecs::query(curGunMod) <| $ [es] (weapon_mod_dot_active : bool)
        if weapon_mod_dot_active
          sendEvent(agent.eid, [[CmdWeapModActivate slotId=human_weap_dot_currentGunSlot, activate=false]])
    return EBehResult ER_SUCCESS

[beh_node(name="visualLog")]
class VisualLog : BehNodeAdapter
  msg : string = "msg"

  def override loadFromBlk(var data : DataBlock) : void
    msg = datablock_getStr(data, "msg", msg)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent != null
      visual_log("{agent.eid}: {msg}")
    else
      visual_log(msg)
    return EBehResult ER_SUCCESS

def is_point_safe(pos, member_team)
  if !has_active_human_battle_area_at(pos, member_team)
    return false
  var danger = ecs::find_query() <| $[es](transform : float3x4; sphere_zone_dot_radius : float;
                                          dmgzone_dot_damage, dmgzone_dot_fireAffect : float)
    if length_sq(inverse(transform) * pos) <= square(sphere_zone_dot_radius)
      if dmgzone_dot_damage > 0. || dmgzone_dot_fireAffect > 0.
        return true
    return false;
  if danger
    return false
  danger = find_query() <| $[es](artillery_dot_targetPos : float3; artillery_dot_dispersion : float)
    let distSq = length_sq(artillery_dot_targetPos - pos)
    return distSq <= square(artillery_dot_dispersion)
  return !danger


[beh_node(name="getOrderPosition")]
class GetOrderPosition : BehNodeAdapter
  posParam : int = -1
  orderPosParam : int = -1

  spreadAroundOrderPoint : float2 = float2(1.2, 1.4)

  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    posParam = agent.blackBoard |> get_or_create(datablock_getStr(data, "posParam", "wishPosition"), agent.pos)
    orderPosParam = agent.blackBoard |> get_or_create(datablock_getStr(data, "orderPosParam", "wishPosition"), agent.pos)
    spreadAroundOrderPoint = data |> datablock_getPoint2("spreadAroundOrderPoint",  float2(1.2, 1.4))

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    let oldPos = datablock_getPoint3(agent.blackBoard, posParam)
    datablock_setPoint3(agent.blackBoard, orderPosParam, oldPos)

    query(agent.eid) <| $ [es] (squad_member_dot_squad : ecs::EntityId; squad_member_dot_orderType : int; squad_member_dot_offset : float3 const&)
      query(squad_member_dot_squad) <| $[es](squad_dot_leader : ecs::EntityId; squad_dot_orderType : int; squad_dot_regroupPos : float3)
        if squad_member_dot_orderType != int(SquadMateOrder ESMO_NO_ORDER) || squad_dot_leader == agent.eid || length_sq(squad_member_dot_offset) < FLT_EPSILON
          return

        var targetTm : float3x4
        identity(targetTm)
        var swim = false

        query(squad_dot_leader) <| $[es](transform : float3x4; human_net_phys_dot_isSwimming : bool = false)
          targetTm = transform
          swim = human_net_phys_dot_isSwimming
        targetTm[3] = squad_dot_regroupPos

        let followLead = squad_dot_orderType == int(SquadOrder ESO_FOLLOW_ME)
        let wishPosition = find_best_squad_pos(targetTm, squad_member_dot_offset, spreadAroundOrderPoint.x, followLead, swim)

        if is_point_safe(wishPosition, agent.teamId)
          datablock_setPoint3(agent.blackBoard, orderPosParam, wishPosition)
    return EBehResult ER_SUCCESS


[beh_node(name="getRegroupPos")]
class GetRegroupPos : BehNodeAdapter
  posParam : int = -1
  squadEid : ecs::EntityId = ecs::INVALID_ENTITY_ID

  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    squadEid = get_Eid(agent.eid, "squad_member.squad") ?? ecs::INVALID_ENTITY_ID
    posParam = agent.blackBoard |> get_or_create(datablock_getStr(data, "posParam", "wishPosition"), agent.pos)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    query(squadEid) <| $[es](squad_dot_regroupPos : float3; squad_dot_leader : ecs::EntityId)
      if squad_dot_leader != agent.eid
        datablock_setPoint3(agent.blackBoard, posParam, squad_dot_regroupPos)
    return EBehResult ER_SUCCESS


[beh_node(name="leaderBehaviour")]
class LeaderBehaviour : BehNodeAdapter
  squadEid : ecs::EntityId = ecs::INVALID_ENTITY_ID
  posParam : int = -1
  updateInterval : float = 2.5
  recalculateTresholdSq : float = 1.f
  updateParam : int = -1

  def override loadFromBlk(var data : DataBlock) : void
    var agent = beh_tree_entity_agent(*owner)
    squadEid = get_Eid(agent.eid, "squad_member.squad") ?? ecs::INVALID_ENTITY_ID
    updateInterval = data |> datablock_getReal("updateInterval", updateInterval)
    recalculateTresholdSq = square(data |> datablock_getReal("recalculateTreshold", updateInterval))
    posParam = agent.blackBoard |> get_or_create(datablock_getStr(data, "posParam", "wishPosition"), agent.pos)
    updateParam = agent.blackBoard |> get_or_create("leaderBehaviourUpdate", 2.5)

  def override update(dt : float) : EBehResult
    var agent = beh_tree_entity_agent(*owner)
    if agent == null
      return EBehResult ER_FAILED

    if get_sync_time() < (agent.blackBoard |> datablock_getReal(updateParam))
      return EBehResult ER_FAILED

    let curPos : float3 = datablock_getPoint3(agent.blackBoard, posParam)
    var nextPos : float3 = curPos

    var isLeader = false
    query(squadEid) <| $[es](squad_dot_leader : ecs::EntityId)
      if squad_dot_leader != agent.eid
        return
      isLeader = true

      let maxDist = 1000.0
      let teamHash = string(agent.teamId)
      var alreadyOnRoute = false

      ecs::find_query() <| $ [es(REQUIRE=capzone_dot_progress)] (transform : float3x4; capzone_dot_owningTeam : int; capzone_dot_maxTeamPresence : int;
                                                                capzone_dot_hasNearestNavmeshPos : bool; var capzone_dot_nearestNavmeshPos : float3;
                                                                teamPresence : ecs::Object; active : bool)
        if !active || agent.teamId == capzone_dot_owningTeam || !capzone_dot_hasNearestNavmeshPos
          return false
        var zonePos = transform[3];
        let distSq = distance_sq(zonePos, agent.pos)
        if distSq > square(maxDist)
          return false
        let myTeamInZone = teamPresence[teamHash] != null ? get_ecs_array(deref(teamPresence[teamHash])) : null
        if myTeamInZone != null && length(*myTeamInZone) > capzone_dot_maxTeamPresence
          return false
        if capzone_dot_nearestNavmeshPos == curPos
          alreadyOnRoute = true
          return true
        return false

      if alreadyOnRoute
        return
      var validZones : array<float3>
      var allZones : array<float3>
      ecs::query() <| $ [es(REQUIRE=capzone_dot_progress)] (transform : float3x4; capzone_dot_owningTeam : int; capzone_dot_maxTeamPresence : int;
                                                            capzone_dot_hasNearestNavmeshPos : bool; var capzone_dot_nearestNavmeshPos : float3;
                                                            teamPresence : ecs::Object; active : bool)
        if !active || !capzone_dot_hasNearestNavmeshPos
          return
        var zonePos = transform[3]
        let distSq = distance_sq(zonePos, agent.pos)
        if distSq > square(maxDist)
          return
        let myTeamInZone = teamPresence[teamHash] != null ? get_ecs_array(deref(teamPresence[teamHash])) : null
        if myTeamInZone != null
          if length(*myTeamInZone) > capzone_dot_maxTeamPresence
            return
        zonePos = capzone_dot_nearestNavmeshPos
        let hasPath = pathfinder::find_path(agent.pos, zonePos, 0.5, 1.0, 0.25)
        if hasPath
          if agent.teamId != capzone_dot_owningTeam
            validZones |> push(zonePos)
          allZones |> push(zonePos)

      if length(validZones) > 0
        nextPos = validZones[grnd() % length(validZones)]
        return

      var validPoints : array<float3>
      ecs::query() <| $ [es] (pointsOfInterest : ecs::Object)
        if has(pointsOfInterest, teamHash)
          let pointsData = pointsOfInterest[teamHash]
          let points = pointsData != null ? get_ecs_array(*pointsData) : null
          if points != null
            for child in *points
              push(validPoints, get_Point3(child) ?? float3())
      for p in validPoints
        if p == curPos
          alreadyOnRoute = true
          break

      if !alreadyOnRoute && length(validPoints) > 0
        nextPos = validPoints[grnd() % length(validPoints)]
        return

      if length(allZones) > 0
        nextPos = allZones[grnd() % length(allZones)]
        return
      nextPos = curPos

    if !isLeader
      return EBehResult ER_FAILED

    agent.blackBoard |> datablock_setReal(updateParam, get_sync_time() + updateInterval)
    datablock_setPoint3(agent.blackBoard, posParam, nextPos)
    return (length_sq(nextPos - curPos) > recalculateTresholdSq) ? EBehResult ER_SUCCESS : EBehResult ER_FAILED
