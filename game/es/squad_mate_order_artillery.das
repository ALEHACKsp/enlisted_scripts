require ecs
require EnlistedWalkerai
require DagorDataBlock
require game.es.events
require enlisted.game.es.enlisted_events
require game.es.squad_common
require game.es.sound.sound_events
require soundHash
require EnlistedWeapon
require HumanPhys
require enlisted.game.es.artillery_radio_common
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq

def get_squad_radioman(squad_eid : ecs::EntityId; squad_dot_leader : ecs::EntityId) : MemberForOrder
  return get_nearest_squad_mate_for_order(squad_eid, squad_dot_leader, SquadMateOrder ESMO_ARTILLERY) <| $(eid:EntityId)
    var hasRadio = false
    ecs::query(eid) <| $ [es(REQUIRE=walker_agent)] (human_weap_dot_gunEids : ecs::EidList)
      let weapEid = human_weap_dot_gunEids[int(HUWeaponSlots EWS_SECONDARY)]
      hasRadio = weapEid != INVALID_ENTITY_ID && has(weapEid, "radio_use")
    return hasRadio

def prepare_artillery_strike(squad_eid, squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int) : bool
  let radioMan = get_squad_radioman(squad_eid, squad_dot_leader)
  if radioMan.executeOrder
    return true
  if radioMan.eid == INVALID_ENTITY_ID || radioMan.eid == squad_dot_leader
    if squad_dot_numAliveMembers <= 1
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad_dot_leader, "no_alive_squadmates", "{SquadMateOrder ESMO_ARTILLERY}")
    else
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="artillery_order/no_radioman"]])
      send_order_cancel_bq(squad_dot_leader, "no_radioman", "{SquadMateOrder ESMO_ARTILLERY}")
    return false

  var ordered = false

  ecs::query(radioMan.eid) <| $ [es] (var squad_member_dot_orderType : int&;
                                  var squad_member_dot_orderUseEntity : ecs::EntityId&;
                                  var walker_agent : EntityAgent)
    walker_agent.blackBoard |> datablock_setBool("artilleryShouldSend", false)
    walker_agent.blackBoard |> datablock_setInt("artilleryRequester", int(uint(squad_dot_leader)))
    squad_member_dot_orderType = int(SquadMateOrder ESMO_ARTILLERY)
    squad_member_dot_orderUseEntity = INVALID_ENTITY_ID
    ordered = true

  if ordered
    send_squad_member_accept_order_bq(squad_dot_leader, "{SquadMateOrder ESMO_ARTILLERY}")
  return ordered

[es(tag=server)]
def on_squad_mate_artillery_order_over(evt:RequestArtilleryOverOrder; eid : ecs::EntityId)
  let squad_eid = eid
  ecs::find_query() <| $ [es] (squad_member_dot_squad : ecs::EntityId;
                               var squad_member_dot_orderType : int&;
                               var squad_member_dot_orderPosition : float3&;
                               var squad_member_dot_orderUseEntity : ecs::EntityId&;
                               var walker_agent : EntityAgent)
    if squad_member_dot_squad != squad_eid
      return false
    if squad_member_dot_orderType != int(SquadMateOrder ESMO_ARTILLERY)
      return false

    if evt.active
      squad_member_dot_orderPosition = evt.targetPos
      walker_agent.blackBoard |> datablock_setBool("artilleryShouldSend", true)
    else
      if (walker_agent.blackBoard |> datablock_getBool("artilleryShouldSend", false))
        return false
      reset_squad_mate_order(squad_member_dot_orderType, squad_member_dot_orderPosition, squad_member_dot_orderUseEntity)
      walker_agent.blackBoard |> datablock_setInt("artilleryRequester", 0)
      walker_agent.blackBoard |> datablock_setBool("artilleryShouldSend", false)
    return true

[es(tag=server)]
def on_squad_mate_artillery_order(evt:RequestSquadMateOrder; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_ARTILLERY && can_order_artillery_strike(squad_dot_leader, eid)
    prepare_artillery_strike(eid, squad_dot_leader, squad_dot_numAliveMembers)

[es(tag=gameClient)]
def on_squad_mate_artillery_order_open_map(evt:RequestSquadMateOrder; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId)
  if evt.orderType == SquadMateOrder ESMO_ARTILLERY && can_order_artillery_strike(squad_dot_leader, eid)
    send_schemeless_event(squad_dot_leader, typeinfo(undecorated_typename type<CmdOpenArtilleryMap>))

[es (on_event=EventEntityDied, tag=server)]
def on_squad_mate_artillery_died_es(evt:Event; eid: EntityId; squad_member_dot_squad : ecs::EntityId; squad_member_dot_orderType : int; squad_dot_numAliveMembers : int)
  if squad_member_dot_orderType == int(SquadMateOrder ESMO_ARTILLERY)
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_ARTILLERY}")
    ecs::query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId)
      prepare_artillery_strike(squad_member_dot_squad, squad_dot_leader, squad_dot_numAliveMembers)

[es(tag=server, no_order)]
def on_squad_mate_artillery_es(act : ecs::UpdateStageInfoAct;
                                squad_member_dot_squad : ecs::EntityId;
                                var walker_agent : EntityAgent;
                                var squad_member_dot_orderType : int&;
                                var squad_member_dot_orderPosition : float3&;
                                var squad_member_dot_orderUseEntity : ecs::EntityId&)
  if int(squad_member_dot_orderType) != int(SquadMateOrder ESMO_ARTILLERY)
    return
  ecs::query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId)
    if walker_agent.blackBoard |> datablock_getInt("artilleryRequester", 0) != int(uint(squad_dot_leader))
      reset_squad_mate_order(squad_member_dot_orderType, squad_member_dot_orderPosition, squad_member_dot_orderUseEntity)
      walker_agent.blackBoard |> datablock_setInt("artilleryRequester", 0)
      walker_agent.blackBoard |> datablock_setBool("artilleryShouldSend", false)

[es (tag=server)]
def squad_mate_order_artillery_es_event_handler(evt : RequestSquadMateOrder; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId)
  if evt.orderType == SquadMateOrder ESMO_ARTILLERY
    let radioman = get_squad_radioman(eid, squad_dot_leader)
    if radioman.eid != INVALID_ENTITY_ID && !radioman.executeOrder
      sendEvent(squad_dot_leader, [[CmdRequestHumanSpeech phrase=sound_hash("squadPrepareArtilleryOrder"), threshold=1.]])
