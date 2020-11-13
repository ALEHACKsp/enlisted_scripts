require ecs
require game.utils.team
require EnlistedWalkerai
require GridCollision
require RendInst
require Dacoll
require HumanPhys
require EnlistedWeapon
require DaWeaponProps
require game.es.events
require game.es.squad_common
require enlisted.game.es.enlisted_events
require game.es.battle_area_common
require zones

def get_alive_num_in_squad(squad_eid : EntityId) : int
  return get_int(squad_eid, "squad.numAliveMembers") ?? 0

[es(tag=gameClient, REQUIRE=human_context_command_input, no_order)]
def human_pre_context_command(act : ecs::UpdateStageInfoAct; squad_member_dot_squad : ecs::EntityId; isInVehicle: bool;
                              human_context_command_dot_nextUpdateTime : float;
                              var human_context_command_dot_orderType: int&)
  if act.curTime >= human_context_command_dot_nextUpdateTime
    if !isInVehicle && get_alive_num_in_squad(squad_member_dot_squad) > 1
      human_context_command_dot_orderType = int(ContextCommand ECC_NONE)
    else
      human_context_command_dot_orderType = int(ContextCommand ECC_DISABLED)

[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_context_command_defend_point)]
def human_post_context_command(act : ecs::UpdateStageInfoAct;
                              human_context_command_dot_updateInterval : float;
                              var human_context_command_dot_nextUpdateTime : float&)
  if act.curTime >= human_context_command_dot_nextUpdateTime
    human_context_command_dot_nextUpdateTime = act.curTime + human_context_command_dot_updateInterval


[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_pre_context_command)]
def human_revive_context_command(act : ecs::UpdateStageInfoAct; isDowned, isAlive: bool;
                                human_context_command_dot_nextUpdateTime : float;
                                var human_context_command_dot_orderType: int&)
  if act.curTime >= human_context_command_dot_nextUpdateTime && human_context_command_dot_orderType == int(ContextCommand ECC_NONE)
    if isAlive && isDowned
      human_context_command_dot_orderType = int(ContextCommand ECC_REVIVE)


[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_revive_context_command)]
def human_context_command_control_zone(act : ecs::UpdateStageInfoAct; human_dot_lookAtZone : ecs::EntityId;
                                      human_context_command_dot_nextUpdateTime : float;
                                      team: int;
                                      var human_context_command_dot_orderType: int&;
                                      var human_context_command_dot_orderUseEntity: ecs::EntityId&)
  if act.curTime >= human_context_command_dot_nextUpdateTime && human_context_command_dot_orderType == int(ContextCommand ECC_NONE)
    if human_dot_lookAtZone != ecs::INVALID_ENTITY_ID && has(human_dot_lookAtZone, "transform")
      let transform = get_TMatrix(human_dot_lookAtZone, "transform")
      if transform != null && has_active_human_battle_area_at((*transform)[3], team)
        human_context_command_dot_orderType = int(ContextCommand ECC_DEFEND_POINT)
        human_context_command_dot_orderUseEntity = human_dot_lookAtZone


[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_context_command_control_zone)]
def human_context_command_defend_point(act : ecs::UpdateStageInfoAct;
                                      human_dot_aimTm : float3x4; team : int;
                                      human_weap_dot_currentGunEid : EntityId;
                                      human_context_command_dot_nextUpdateTime : float;
                                      var human_context_command_dot_orderType: int&;
                                      var human_context_command_dot_orderPosition: float3&;
                                      var human_context_command_dot_orderUseEntity: ecs::EntityId&;
                                      squad_member_dot_squad : ecs::EntityId&)
  if act.curTime >= human_context_command_dot_nextUpdateTime &&  human_context_command_dot_orderType == int(ContextCommand ECC_NONE)
    var traceDir = human_dot_aimTm[0]
    var tracePos = human_dot_aimTm[3]
    var len = 100.0
    var norm : float3
    var height = 100.0
    var new_orderPosition : float3

    ecs::query(squad_member_dot_squad) <| $[es](squad_dot_maxOrderDistance : float; squad_dot_orderDistanceSub : float)
      len = squad_dot_maxOrderDistance - squad_dot_orderDistanceSub

    let matId = get_int(human_weap_dot_currentGunEid, "gun.aimRayMatId") ?? -1
    var pmid : int
    var riDesc : RendInstDesc
    traceray_normalized(tracePos, traceDir, len, pmid, norm, ETF_DEFAULT, riDesc, matId)
    new_orderPosition = tracePos + traceDir * len
    tracedown_normalized(new_orderPosition + float3(0.0, 0.05, 0.0), height, ETF_DEFAULT)
    new_orderPosition.y -= height

    if !has_active_human_battle_area_at(new_orderPosition, team)
      return

    human_context_command_dot_orderType = int(ContextCommand ECC_DEFEND_POINT)
    human_context_command_dot_orderUseEntity = ecs::INVALID_ENTITY_ID
    human_context_command_dot_orderPosition = new_orderPosition

    GridCollision::trace_grid_objects(tracePos, traceDir, len, GridType GT_DEFAULT) <| $(intersections:array<IntersectedEntity>#)
      var foundTarget = false
      for it in intersections
        ecs::query(it.eid) <| $[es(REQUIRE="vehicle_seats.seats")] (isAlive : bool; vehicle_seats_dot_restrictToTeam : int = TEAM_UNASSIGNED)
          if !isAlive
            return
          foundTarget = true
          if vehicle_seats_dot_restrictToTeam == TEAM_UNASSIGNED || is_teams_friendly(vehicle_seats_dot_restrictToTeam, team)
            human_context_command_dot_orderType = int(ContextCommand ECC_DEFEND_POINT)
            human_context_command_dot_orderUseEntity = it.eid
          else
            human_context_command_dot_orderType = int(ContextCommand ECC_ATTACK_TARGET)
            human_context_command_dot_orderUseEntity = it.eid
        if foundTarget
          break


[es(tag=gameClient, REQUIRE=human_context_command_input)]
def human_context_command_req(evt : RqContextCommand; eid, squad_member_dot_squad : ecs::EntityId;
                              human_context_command_dot_orderType: int;
                              human_context_command_dot_orderPosition : float3;
                              human_context_command_dot_orderUseEntity: ecs::EntityId)
  let orderDefendPoint = human_context_command_dot_orderType == int(ContextCommand ECC_DEFEND_POINT)
  if human_context_command_dot_orderType == int(ContextCommand ECC_CANCEL)
    sendEvent(squad_member_dot_squad, [[RequestSquadOrder orderType=SquadOrder ESO_FOLLOW_ME, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  elif orderDefendPoint || human_context_command_dot_orderType == int(ContextCommand ECC_ATTACK_TARGET)
    var orderType = orderDefendPoint ? SquadOrder ESO_DEFEND_POINT : SquadOrder ESO_ATTACK_TARGET
    var orderPosition = human_context_command_dot_orderPosition
    var orderUseEntity = human_context_command_dot_orderUseEntity
    if orderUseEntity != ecs::INVALID_ENTITY_ID
      let targetTM = get_TMatrix(orderUseEntity, "transform")
      if targetTM != null
        orderPosition = (*targetTM)[3]
      if orderDefendPoint && has(orderUseEntity, "vehicle_seats.seats")
        orderType = SquadOrder ESO_USE_VEHICLE
    sendEvent(squad_member_dot_squad, [[RequestSquadOrder orderType=orderType, orderPosition=orderPosition, orderUseEntity=orderUseEntity]])
  elif human_context_command_dot_orderType == int(ContextCommand ECC_REVIVE)
    sendEvent(squad_member_dot_squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_HEAL, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  elif human_context_command_dot_orderType == int(ContextCommand ECC_BRING_AMMO)
    sendEvent(squad_member_dot_squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_BRING_AMMO, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  elif human_context_command_dot_orderType == int(ContextCommand ECC_DISABLED) && get_alive_num_in_squad(squad_member_dot_squad) <= 1
    sendEvent(eid, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])

[es(tag=gameClient, REQUIRE=human_context_command_input)]
def human_context_command_all_cancel_req(evt : RqCancelContextCommand; eid, squad_member_dot_squad : ecs::EntityId)
  let squadEid = squad_member_dot_squad
  var hasGlobalOrder = false
  ecs::query(squad_member_dot_squad) <| $[es](squad_dot_orderType : int)
    hasGlobalOrder = squad_dot_orderType != int(SquadOrder ESO_FOLLOW_ME)
  var hasOrder = hasGlobalOrder
  if !hasOrder && evt.include_personal_orders
    ecs::find_query() <| $ [es] (squad_member_dot_squad : ecs::EntityId; isAlive : bool; squad_member_dot_orderType : int)
      hasOrder = squadEid == squad_member_dot_squad && isAlive && squad_member_dot_orderType != int(SquadOrder ESO_FOLLOW_ME)
      return hasOrder
  if hasGlobalOrder
    sendEvent(squad_member_dot_squad, [[RequestSquadOrder orderType=SquadOrder ESO_FOLLOW_ME, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  if evt.include_personal_orders
    sendEvent(squad_member_dot_squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_NO_ORDER, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  if hasOrder
    sendEvent(eid, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/all_orders_canceled"]])
