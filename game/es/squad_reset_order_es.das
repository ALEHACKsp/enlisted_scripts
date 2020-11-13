require ecs
require EnlistedWalkerai
require math
require zones
require DagorDataBlock
require game.es.events
require game.es.squad_common
require enlisted.game.es.enlisted_events
require game.es.battle_area_common
require game.utils.team
require math.base
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq

def get_entity_transform(eid : EntityId) : float3x4 const?
  return get_TMatrix(eid, "transform")

[es(tag=server, no_order)]
def squad_reset_attack_order_es(act : ecs::UpdateStageInfoAct; eid, squad_dot_leader:EntityId;
                                var squad_dot_orderType : int&;
                                var squad_dot_orderUseEntity : ecs::EntityId&)
  if squad_dot_orderType != int(SquadOrder ESO_ATTACK_TARGET)
    return
  var hasAttackTarget = collect_squad_ai(eid, squad_dot_leader) <| $(var walker_agent:EntityAgent)
    return walker_agent.blackBoard |> datablock_getInt("attackTarget", 0) != 0

  if !hasAttackTarget
    reset_squad_order(squad_dot_orderType, squad_dot_orderUseEntity)
    send_order_cancel_bq(squad_dot_leader, "no_attack_target", "{SquadOrder ESO_ATTACK_TARGET}")

[es (tag=server, no_order)]
def squad_reset_order_far_away_es(act : ecs::UpdateStageInfoAct; eid, squad_dot_leader : ecs::EntityId; squad_dot_orderPosition : float3 const&;
                                  squad_dot_maxOrderDistance : float; var squad_dot_orderUseEntity : EntityId&; var squad_dot_orderType : int&)
  if !squad_dot_leader || (squad_dot_orderType != int(SquadOrder ESO_DEFEND_POINT) && squad_dot_orderType != int(SquadOrder ESO_USE_VEHICLE))
    return
  if squad_dot_orderType == int(SquadOrder ESO_DEFEND_POINT) && squad_dot_orderUseEntity != INVALID_ENTITY_ID // ignore "control point" orders
    return
  let leaderTm = get_entity_transform(squad_dot_leader)
  if leaderTm == null
    return

  if distance_sq(squad_dot_orderPosition, (*leaderTm)[3]) >= square(squad_dot_maxOrderDistance)
    let isMembersTooFar = collect_squad(eid, squad_dot_leader) <| $(member_eid : EntityId)
      let member_transform = get_TMatrix(member_eid, "transform")
      if member_transform != null
        return distance_sq((*member_transform)[3], (*leaderTm)[3]) >= square(squad_dot_maxOrderDistance)
      return false

    if isMembersTooFar
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command_canceled/to_far"]])
      reset_squad_order(squad_dot_orderType, squad_dot_orderUseEntity)
      send_order_cancel_bq(squad_dot_leader, "to_far", "{SquadOrder ESO_DEFEND_POINT}")

[es (REQUIRE=battle_area, tag=server)]
def squad_reset_order_on_battlearea_deactivation_es(evt : EventEntityActivate; eid : ecs::EntityId)
  let activate = get_bool(evt.data, "activate") ?? false
  if activate
    return
  ecs::query() <| $[es](persistentSquadOrder_dot_orderPosition : float3 const&;
                        team : int;
                        var persistentSquadOrder_dot_orderType : int&;
                        var persistentSquadOrder_dot_orderUseEntity : ecs::EntityId&)
    if !has_active_human_battle_area_at(persistentSquadOrder_dot_orderPosition, team, eid)
      persistentSquadOrder_dot_orderUseEntity = ecs::INVALID_ENTITY_ID
      persistentSquadOrder_dot_orderType = int(SquadOrder ESO_FOLLOW_ME)
  ecs::query() <| $[es](squad_dot_orderPosition : float3 const&; squad_dot_leader : ecs::EntityId;
                        var squad_dot_orderType : int&; var squad_dot_orderUseEntity : ecs::EntityId&)
    let leaderTeam = get_int(squad_dot_leader, "team") ?? TEAM_UNASSIGNED
    if !has_active_human_battle_area_at(squad_dot_orderPosition, leaderTeam, eid)
      reset_squad_order(squad_dot_orderType, squad_dot_orderUseEntity)
      send_order_cancel_bq(squad_dot_leader, "battlearea_deactivation", "{SquadOrder ESO_DEFEND_POINT}")

[es (REQUIRE=capzone, tag=server)]
def squad_reset_order_on_capzone_update_es(evt:EventEntityActivate)
  let activate = get_bool(evt.data, "activate") ?? false
  if activate
    return
  ecs::query() <| $[es](var persistentSquadOrder_dot_orderType : int&; var persistentSquadOrder_dot_orderUseEntity : EntityId&)
    persistentSquadOrder_dot_orderUseEntity = INVALID_ENTITY_ID
    persistentSquadOrder_dot_orderType = int(SquadOrder ESO_FOLLOW_ME)
  ecs::query() <| $[es](squad_dot_leader : ecs::EntityId; var squad_dot_orderType : int&; var squad_dot_orderUseEntity : ecs::EntityId&)
    reset_squad_order(squad_dot_orderType, squad_dot_orderUseEntity)
    send_order_cancel_bq(squad_dot_leader, "capzone_update", "{squad_dot_orderType}")
