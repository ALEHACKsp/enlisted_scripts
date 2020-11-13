require ecs
require EnlistedWalkerai
require pathfinder
require DagorDataBlock
require DagorRandom
require math
require game.es.events
require enlisted.game.es.enlisted_events
require game.es.squad_common
require game.es.sound.sound_events
require soundHash
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq

def order_heal(squad_eid, squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int) : bool
  let isLeaderDowned = get_bool(squad_dot_leader, "isDowned") ?? false
  var ordered = false
  let nearestTeammate = get_nearest_squad_mate_for_order(squad_eid, squad_dot_leader, SquadMateOrder ESMO_HEAL) <| $(eid:EntityId)
    return isLeaderDowned ? (get_int(eid, "total_kits.targetRevive") ?? 0 > 0) : (get_int(eid, "total_kits.targetHeal") ?? 0 > 0)
  if nearestTeammate.executeOrder
    return true
  if nearestTeammate.eid != INVALID_ENTITY_ID
    ecs::query(nearestTeammate.eid) <| $ [es] (var squad_member_dot_orderType : int&;
                                          var squad_member_dot_orderPosition : float3&;
                                          var squad_member_dot_orderUseEntity : ecs::EntityId&; var walker_agent : EntityAgent)
      walker_agent.blackBoard |> datablock_setInt("healRequester", int(uint(squad_dot_leader)))
      squad_member_dot_orderType = int(SquadMateOrder ESMO_HEAL)
      squad_member_dot_orderPosition = float3()
      squad_member_dot_orderUseEntity = INVALID_ENTITY_ID
      sendEvent(nearestTeammate.eid, [[CmdRequestHumanSpeech phrase=sound_hash("confirmResponseDelayed"), threshold=1.]])
      ordered = true
  if !ordered
    if squad_dot_numAliveMembers <= 1
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad_dot_leader, "no_alive_squadmates", "{SquadMateOrder ESMO_HEAL}")
    else
      let text = isLeaderDowned ? "revive_order/no_revive_kits" : "heal_order/no_medkits"
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text=text]])
      send_order_cancel_bq(squad_dot_leader, isLeaderDowned ? "no_revive_kits" : "no_medkits",
        "{SquadMateOrder ESMO_HEAL}")
  else
    query(nearestTeammate.eid) <| $[es](transform : float3x4)
      send_squad_member_accept_order_bq(squad_dot_leader, "{SquadMateOrder ESMO_HEAL}", transform[3], true)
  return ordered

[es(tag=server)]
def on_squad_mate_heal_order(evt:RequestSquadMateOrder; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_HEAL
    order_heal(eid, squad_dot_leader, squad_dot_numAliveMembers)

[es (on_event=EventEntityDied, tag=server)]
def on_squad_mate_should_heal_died(evt:Event; eid : EntityId; squad_member_dot_squad : ecs::EntityId; squad_member_dot_orderType : int)
  if squad_member_dot_orderType == int(SquadMateOrder ESMO_HEAL)
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_HEAL}")
    ecs::query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int)
      order_heal(squad_member_dot_squad, squad_dot_leader, squad_dot_numAliveMembers)

[es(tag=server, no_order)]
def on_squad_mate_heal(act : ecs::UpdateStageInfoAct; squad_member_dot_squad : ecs::EntityId;
                                     var walker_agent : EntityAgent; var squad_member_dot_orderType : int&;
                                     var squad_member_dot_orderPosition : float3&; var squad_member_dot_orderUseEntity : ecs::EntityId&)
  if squad_member_dot_orderType == int(SquadMateOrder ESMO_HEAL)
    ecs::query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId)
      if walker_agent.blackBoard |> datablock_getInt("healRequester", 0) != int(uint(squad_dot_leader))
        walker_agent.blackBoard |> datablock_setInt("healRequester", 0)
        reset_squad_mate_order(squad_member_dot_orderType, squad_member_dot_orderPosition, squad_member_dot_orderUseEntity)

[es (tag=server)]
def squad_mate_order_heal(evt : RequestSquadMateOrder; squad_dot_leader : ecs::EntityId)
  if evt.orderType == SquadMateOrder ESMO_HEAL
    if get_bool(squad_dot_leader, "isDowned") ?? false
      sendEvent(squad_dot_leader, [[CmdRequestHumanSpeech phrase=sound_hash("squadReviveMeOrder"), threshold=1.]])
    else
      sendEvent(squad_dot_leader, [[CmdRequestHumanSpeech phrase=sound_hash("squadHealMeOrder"), threshold=1.]])

[es (tag=server, track=human_inventory_dot_entityToUse)]
def squad_mate_order_heal_interrupted(evt : Event;
                                      human_inventory_dot_entityToUse : EntityId;
                                      human_inventory_dot_targetToUse : EntityId;
                                      var walker_agent : EntityAgent;
                                      var squad_member_dot_orderType : int&;
                                      var squad_member_dot_orderPosition : float3&;
                                      var squad_member_dot_orderUseEntity : ecs::EntityId&;
                                      squad_member_dot_squad : ecs::EntityId)
  if squad_member_dot_orderType == int(SquadMateOrder ESMO_HEAL)
    query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId)
      if !human_inventory_dot_entityToUse || human_inventory_dot_targetToUse != squad_dot_leader
        walker_agent.blackBoard |> datablock_setInt("healRequester", 0)
        reset_squad_mate_order(squad_member_dot_orderType, squad_member_dot_orderPosition, squad_member_dot_orderUseEntity)
