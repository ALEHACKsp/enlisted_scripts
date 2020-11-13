require ecs
require app
require math.base
require EnlistedWalkerai
require pathfinder
require DagorDataBlock
require DagorRandom
require math
require game.es.squad_common
require game.es.sound.sound_events
require game.es.vehicle.vehicle_events
require game.es.events
require game.es.battle_area_common
require soundHash
require zones
require DagorMath
require game.utils.team

let
  follow_recalc_dist = 1.0
  max_time_without_regroup = 30.0
  min_regroup_dist = 1.1
  already_moving_speed = 0.5

[es (tag=server, track=squad_dot_leader)]
def track_change_leader_in_squad(evt : Event; squad_dot_leader : ecs::EntityId;
                                 var squad_dot_leaderCachedPositions: Point3List;
                                 var squad_dot_leaderCachedPositionsNextUpdateTime : float&;
                                 squad_dot_leaderCachedPositionsUpdateInterval : float)
  squad_dot_leaderCachedPositionsNextUpdateTime = get_sync_time() + squad_dot_leaderCachedPositionsUpdateInterval
  clear(squad_dot_leaderCachedPositions)
  query(squad_dot_leader) <| $[es](transform : float3x4)
    push_back(squad_dot_leaderCachedPositions, transform[3])

[es (tag=server, no_order)]
def squad_mode_es(info : ecs::UpdateStageInfoAct;
                  eid : ecs::EntityId;
                  squad_dot_leader : ecs::EntityId;
                  squad_dot_regroupPos : float3;
                  var squad_dot_leaderCachedPositionsNextUpdateTime : float&;
                  squad_dot_leaderCachedPositionsUpdateInterval : float;
                  var squad_dot_leaderCachedPositions: Point3List;
                  squad_dot_leaderCachedPositionsMax : int;
                  squad_dot_offensiveModeDistTreshold : float;
                  squad_dot_enableAutoSelectAIMode : bool;
                  var squad_dot_AIMode : int&;
                  squad_dot_leaderFollowMeOrderTimeThreshold : float;
                  squad_dot_leaderFollowMeOrderChance : float;
                  var squad_dot_leaderFollowMeOrderNextTime : float&)
  var leaderPos = squad_dot_regroupPos
  query(squad_dot_leader) <| $[es](transform : float3x4)
    leaderPos = transform[3]

  if info.curTime > squad_dot_leaderCachedPositionsNextUpdateTime
    squad_dot_leaderCachedPositionsNextUpdateTime = info.curTime + squad_dot_leaderCachedPositionsUpdateInterval
    while length(squad_dot_leaderCachedPositions) >= squad_dot_leaderCachedPositionsMax
      erase(squad_dot_leaderCachedPositions, 0)
    push_back(squad_dot_leaderCachedPositions, leaderPos)

  if !squad_dot_enableAutoSelectAIMode
    return

  var averageDist = 0.f
  for cachedPos in squad_dot_leaderCachedPositions
    averageDist += length(cachedPos - leaderPos)
  averageDist = safediv(averageDist, float (length(squad_dot_leaderCachedPositions)))

  let isOffensive = averageDist > squad_dot_offensiveModeDistTreshold
  if squad_dot_AIMode == int(AiMode AI_DEFENSIVE) && isOffensive
    if gfrnd() <= squad_dot_leaderFollowMeOrderChance && info.curTime >= squad_dot_leaderFollowMeOrderNextTime
      squad_dot_leaderFollowMeOrderNextTime = info.curTime + squad_dot_leaderFollowMeOrderTimeThreshold
      ecs::query(squad_dot_leader) <| $ [es] (is_watched_sound : bool)
        if is_watched_sound
          let squadEid = eid
          sendEvent(squad_dot_leader, [[CmdRequestHumanSpeech phrase=sound_hash("squadFollowOrder"), threshold=1.]])
          ecs::query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId)
            if squad_member_dot_squad == squadEid && eid != squad_dot_leader
              request_squad_member_response(eid)
  squad_dot_AIMode = isOffensive ? int(AiMode AI_OFFENSIVE) : int(AiMode AI_DEFENSIVE)


[es (tag=server, no_order)]
def squad_es(info : ecs::UpdateStageInfoAct;
             squad_dot_numAliveMembers : int;
             squad_dot_orderUseEntity : ecs::EntityId;
             var squad_dot_leader : ecs::EntityId&;
             var squad_dot_orderType : int&;
             squad_dot_orderPosition : float3;
             var squad_dot_regroupPos : float3&)
  if !doesEntityExist(squad_dot_leader)
    squad_dot_leader = ecs::INVALID_ENTITY_ID
  if squad_dot_numAliveMembers <= 1 || squad_dot_leader == ecs::INVALID_ENTITY_ID
    if squad_dot_orderType != int(SquadOrder ESO_FOLLOW_ME)
      squad_dot_orderType = int(SquadOrder ESO_FOLLOW_ME)

  if squad_dot_orderType == int(SquadOrder ESO_FOLLOW_ME)
    query(squad_dot_leader) <| $[es](transform : float3x4)
      squad_dot_regroupPos = transform[3]
  elif squad_dot_orderType == int(SquadOrder ESO_DEFEND_POINT)
    squad_dot_regroupPos = squad_dot_orderPosition
    query(squad_dot_orderUseEntity) <| $[es](capzone_dot_hasNearestNavmeshPos : bool; var capzone_dot_nearestNavmeshPos : float3)
      if capzone_dot_hasNearestNavmeshPos
        squad_dot_regroupPos = capzone_dot_nearestNavmeshPos
  elif squad_dot_orderType == int(SquadOrder ESO_USE_VEHICLE)
    if get_bool(squad_dot_orderUseEntity, "isAlive") ?? false
      squad_dot_regroupPos = (*get_TMatrix(squad_dot_orderUseEntity, "transform"))[3]


def set_custom_spread_order_point(squad_eid: EntityId; apply_condition: bool; spread = float2())
  query(squad_eid) <| $[es](squad_dot_orderType : int;
                            var squad_dot_spreadAroundOrderPoint : float2&;
                            squad_dot_initialSpreadAroundOrderPoint : float2;
                            squad_dot_defaultIncreasedSpreadAroundOrderPoint = float2(3., 3.))
    let spreadDistance = length_sq(spread) > FLT_EPSILON ? spread : squad_dot_defaultIncreasedSpreadAroundOrderPoint
    if squad_dot_orderType == int(SquadOrder ESO_FOLLOW_ME) && apply_condition
      squad_dot_spreadAroundOrderPoint = spreadDistance
    elif squad_dot_spreadAroundOrderPoint != squad_dot_initialSpreadAroundOrderPoint
      squad_dot_spreadAroundOrderPoint = squad_dot_initialSpreadAroundOrderPoint

[es (track=human_weap_dot_mortarMode, tag=server)]
def mortar_increase_squad_spread(evt : Event; human_weap_dot_mortarMode : bool; squad_member_dot_squad : EntityId)
  set_custom_spread_order_point(squad_member_dot_squad,human_weap_dot_mortarMode)

[es (track=building_action_dot_target, tag=server)]
def building_squad_orderType_spread(evt : Event; building_action_dot_target : EntityId; squad_member_dot_squad : EntityId)
  var spreadAroundBuildingTarget = float2()
  query(building_action_dot_target) <| $[es](buildingRadius : float; buildingDistance : float)
    let radius = 0.5 * buildingDistance + buildingRadius
    spreadAroundBuildingTarget = float2(radius, radius)
  set_custom_spread_order_point(squad_member_dot_squad, building_action_dot_target != INVALID_ENTITY_ID, spreadAroundBuildingTarget)

[es (track=human_anim_dot_vehicleSelected, tag=server)]
def vehicle_increase_squad_spread(evt : Event;
                                  squad_member_dot_squad : EntityId;
                                  human_anim_dot_vehicleSelected : EntityId)
  var spreadAroundSelectedVehicle = float2()
  if human_anim_dot_vehicleSelected != INVALID_ENTITY_ID
    query(human_anim_dot_vehicleSelected) <| $[es(REQUIRE=additiveSquadSpread)](animchar_bbox : bbox3f; additiveSpreadAround = float2(3., 3.))
      spreadAroundSelectedVehicle = additiveSpreadAround
      let radius = 0.5 * length(animchar_bbox.bmax.xz - animchar_bbox.bmin.xz)
      spreadAroundSelectedVehicle.x += radius
      spreadAroundSelectedVehicle.y += radius
  set_custom_spread_order_point(squad_member_dot_squad, length_sq(spreadAroundSelectedVehicle) > FLT_EPSILON, spreadAroundSelectedVehicle)

[es(tag=server)]
def squad_mate_init_beh_tree(evt : EventEntityCreated; transform : float3x4; beh_tree_dot_enabled : bool;
                            var walker_agent : EntityAgent;
                            walker_agent_dot_blackboard_dot_wishPositionSet : bool = false)
  var wishPositionParam = datablock_find_param(walker_agent.blackBoard, "wishPosition")
  if wishPositionParam == -1
    wishPositionParam = datablock_addPoint3(walker_agent.blackBoard, "withPosition", transform[3])
  if beh_tree_dot_enabled && !walker_agent_dot_blackboard_dot_wishPositionSet
    datablock_setPoint3(walker_agent.blackBoard, wishPositionParam, transform[3])

[es(tag=server)]
def squad_request_change_leader_es(evt: RequestSquadChangeLeader; eid: EntityId)
  sendEvent(eid, [[CmdSwitchSquadLeader eid=evt.eid]])