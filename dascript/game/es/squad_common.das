options remove_unused_symbols = false
module squad_common
require ecs
require pathfinder
require DagorRandom
require EnlistedWalkerai
require math
require math.base
require DagorDataBlock
require zones
require game.utils.team


struct MemberForOrder
  eid : EntityId
  executeOrder : bool

def find_best_squad_pos(leader_tm : float3x4; offset : float3; min_distance : float; forceSpread = false; swim = false) : float3
  let extends = 0.8
  var center = leader_tm[3]
  if !swim
    pathfinder::project_to_nearest_navmesh_point(center, extends)

  var wishPosition = leader_tm * offset
  var resPos = wishPosition
  if !swim
    pathfinder::project_to_nearest_navmesh_point(wishPosition, extends)
    pathfinder::traceray_navmesh(center, wishPosition, extends, resPos)
  if length_sq(offset) < FLT_EPSILON
    return resPos

  var positions = [[float3[3] wishPosition; wishPosition; wishPosition]]
  var currentOffset = offset
  for iter in range(0, 2)
    let distSq = distance_sq(resPos, center)
    if distSq >= square(min_distance) && distSq <= 2f * length_sq(currentOffset) && pathfinder::check_path(center, resPos, extends, -1.0, 10.0)
      return resPos
    currentOffset = float3(1 << (iter + 1)) * offset
    wishPosition = leader_tm * currentOffset
    if !swim
      pathfinder::project_to_nearest_navmesh_point(wishPosition, extends)
      pathfinder::traceray_navmesh(center, wishPosition, extends, resPos)
    positions[iter + 1] = wishPosition

  if !forceSpread
    return center

  for iter, pos in range(0, 2), positions
    let distSq = distance_sq(pos, center)
    currentOffset = float3(1 << (iter + 1)) * offset
    if distSq >= square(min_distance) && distSq <= 2f * length_sq(currentOffset) && pathfinder::check_path(center, pos, extends, -1.0, 10.0)
      return pos
  return resPos

[generic]
def request_squad_member_response(member_eid : ecs::EntityId; squad_member_response = "confirm")
  ecs::query(member_eid) <| $ [es] (var squad_member_dot_responseTimer : float&; var squad_member_dot_response : das_string)
    squad_member_dot_responseTimer = 2.0 + gsrnd()
    squad_member_dot_response := squad_member_response

[generic]
def reset_squad_order(var squad_dot_orderType : int&; var squad_dot_orderUseEntity : ecs::EntityId&)
  squad_dot_orderUseEntity = ecs::INVALID_ENTITY_ID
  squad_dot_orderType = int(SquadOrder ESO_FOLLOW_ME)

[generic]
def collect_squad(squad_eid, squad_dot_leader : ecs::EntityId; callback : block<(eid:EntityId):bool>) : bool
  return ecs::find_query() <| $ [es(REQUIRE=walker_agent)] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId; isAlive : bool)
    if isAlive && squad_eid == squad_member_dot_squad && eid != squad_dot_leader
      return invoke(callback, eid)
    return false

[generic]
def collect_squad_ai(squad_eid, squad_dot_leader : ecs::EntityId; callback : block<(var ai:EntityAgent):bool>) : bool
  return ecs::find_query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId; isAlive : bool; var walker_agent : EntityAgent)
    if isAlive && squad_eid == squad_member_dot_squad && eid != squad_dot_leader
      return invoke(callback, walker_agent)
    return false

[generic]
def has_squad_mate_order(squad_eid, squad_dot_leader : ecs::EntityId; order : SquadMateOrder)
  return ecs::find_query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId;
                              isAlive : bool; squad_member_dot_orderType : int)
    if isAlive && squad_eid == squad_member_dot_squad && eid != squad_dot_leader && squad_member_dot_orderType == int(order)
      return true
    return false

def reset_squad_mate_order(var squad_member_dot_orderType : int&; var squad_member_dot_orderPosition : float3&;
                          var squad_member_dot_orderUseEntity : ecs::EntityId&)
  squad_member_dot_orderType = int(SquadMateOrder ESMO_NO_ORDER)
  squad_member_dot_orderPosition = float3()
  squad_member_dot_orderUseEntity = INVALID_ENTITY_ID

def reset_squad_mate_orders(squad_eid, squad_dot_leader : ecs::EntityId)
  ecs::query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId; isAlive : bool;
                          var squad_member_dot_orderType : int&; var squad_member_dot_orderPosition : float3&;
                          var squad_member_dot_orderUseEntity : ecs::EntityId&; var walker_agent : EnlistedWalkerai::EntityAgent)
    if squad_eid == squad_member_dot_squad && eid != squad_dot_leader && isAlive
      walker_agent.blackBoard |> datablock_setInt("ammoRequester", 0)
      walker_agent.blackBoard |> datablock_setInt("healRequester", 0)
      walker_agent.blackBoard |> datablock_setInt("artilleryRequester", 0)
      walker_agent.blackBoard |> datablock_setBool("artilleryShouldSend", false)
      reset_squad_mate_order(squad_member_dot_orderType, squad_member_dot_orderPosition, squad_member_dot_orderUseEntity)

def get_nearest_squad_mate_for_order(squad_eid, squad_dot_leader : ecs::EntityId; order : SquadMateOrder) : MemberForOrder
  return get_nearest_squad_mate_for_order(squad_eid, squad_dot_leader, order) <| $[unused_argument(_)](_:EntityId) => true

def get_nearest_squad_mate_for_order(squad_eid, squad_dot_leader : ecs::EntityId; order : SquadMateOrder; cond: block<(EntityId):bool>) : MemberForOrder
  let leaderTMRef = get_TMatrix(squad_dot_leader, "transform")
  if leaderTMRef == null
    return [[MemberForOrder eid = INVALID_ENTITY_ID, executeOrder = false ]]
  let leaderTM = *leaderTMRef
  var alreadyOrdered = false
  var nearestTeammate = ecs::INVALID_ENTITY_ID
  var minDistSq = 0.0
  ecs::find_query() <| $ [es(REQUIRE=walker_agent)] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId;
                                                    squad_member_dot_orderType : int;
                                                    transform : float3x4; isAlive : bool; isDowned = false)
    if squad_eid != squad_member_dot_squad || eid == squad_dot_leader || !isAlive || isDowned
      return false
    alreadyOrdered = squad_member_dot_orderType == int(order)
    if alreadyOrdered
      nearestTeammate = eid
      return true
    if squad_member_dot_orderType != int(SquadMateOrder ESMO_NO_ORDER) || !invoke(cond, eid)
      return false
    let distSq = distance_sq(transform[3], leaderTM[3])
    if nearestTeammate == ecs::INVALID_ENTITY_ID || distSq < minDistSq
      minDistSq = distSq
      nearestTeammate = eid
    return false

  return [[MemberForOrder eid = nearestTeammate, executeOrder = alreadyOrdered ]]

[generic]
def get_num_alive_squad_members(squad_eid: ecs::EntityId)
  return get_int(squad_eid, "squad.numAliveMembers") ?? 0

[generic]
def get_squad_leader(squad_eid: ecs::EntityId)
  return get_Eid(squad_eid, "squad.leader") ?? ecs::INVALID_ENTITY_ID
