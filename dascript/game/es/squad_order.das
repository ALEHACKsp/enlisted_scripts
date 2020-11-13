require ecs
require ecs.common
require EnlistedWalkerai
require DagorRandom
require DagorDataBlock
require soundHash
require EnlistedWeapon
require game.es.events
require game.es.sound.sound_events
require enlisted.game.es.enlisted_events
require player
require math
require game.es.squad_common
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq

def squad_order_speech(squad_eid : ecs::EntityId; leader_eid : ecs::EntityId; order_type : int; squad_members_response = "confirm") : bool
  if order_type == int(SquadOrder ESO_DEFEND_POINT)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase=sound_hash("squadDefendOrder"), threshold=1.]])
  elif order_type == int(SquadOrder ESO_FOLLOW_ME)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase=sound_hash("squadRegroupOrder"), threshold=1.]])
  elif order_type == int(SquadOrder ESO_USE_VEHICLE)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase=sound_hash("squadUseVehicle"), threshold=1.]])
  elif order_type == int(SquadOrder ESO_ATTACK_TARGET)
    sendEvent(leader_eid, [[CmdRequestHumanSpeech phrase=sound_hash("squadDefendOrder"), threshold=1.]]) // TODO: "squad attack target"
  else
    return false

  if squad_members_response != ""
    ecs::query() <| $ [es(REQUIRE=squad_member)] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId)
      if squad_member_dot_squad == squad_eid
        request_squad_member_response(eid, squad_members_response)

  return true

def has_grenade(eid : EntityId; grenade_type : string) : bool
  var res = false
  ecs::query(eid) <| $[es] (itemContainer : EidList)
    for itemEid in itemContainer
      let itemGrenadeType = get_string(itemEid, "item.grenadeType", "")
      if itemGrenadeType == grenade_type
        res = true
        return
  return res

[es (tag=server)]
def squad_order_es_event_handler(
    evt : RequestSquadOrder;
    eid : ecs::EntityId;
    squad_dot_leader : ecs::EntityId;
    var squad_dot_orderType : int&;
    var squad_dot_orderPosition : float3&;
    var squad_dot_orderUseEntity : ecs::EntityId&)
  squad_dot_orderType = int (evt.orderType)
  squad_dot_orderPosition = evt.orderPosition
  squad_dot_orderUseEntity = evt.orderUseEntity

  var canBeExecute = true
  var canAttack = true
  var attackTarget = squad_dot_orderType == int(SquadOrder ESO_ATTACK_TARGET) ? squad_dot_orderUseEntity : INVALID_ENTITY_ID
  if squad_dot_orderType == int(SquadOrder ESO_ATTACK_TARGET)
    if has(attackTarget, "vehicle_seats.seats")
      canAttack = collect_squad(eid, squad_dot_leader) <| $(member_eid : EntityId)
        return has_grenade(member_eid, "antitank")
    canBeExecute = canAttack
    if !canAttack
      attackTarget = INVALID_ENTITY_ID
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="attack_target/cancelled"]])
      send_order_cancel_bq(squad_dot_leader, "no_antitank_grenade", "{SquadOrder ESO_ATTACK_TARGET}")
  collect_squad_ai(eid, squad_dot_leader) <| $(var walker_agent:EntityAgent)
    walker_agent.blackBoard |> datablock_setInt("attackTarget", int(uint(attackTarget))) // always update attack target to cancel previous if needed
    return false

  squad_order_speech(eid, squad_dot_leader, squad_dot_orderType, canBeExecute ? "confirm" : "reject")
  if !canBeExecute
    reset_squad_order(squad_dot_orderType, squad_dot_orderUseEntity)
    if canAttack
      send_order_cancel_bq(squad_dot_leader, "cant_be_executed", "{squad_dot_orderType}")
  else
    send_squad_member_accept_order_bq(squad_dot_leader, "{squad_dot_orderType}")

def store_persistent_squad_order(
    leader_eid : ecs::EntityId;
    squad_dot_orderType : int;
    squad_dot_orderPosition : float3 const;
    squad_dot_orderUseEntity : ecs::EntityId)
  var playerEid = get_Eid(leader_eid, "possessedByPlr") ?? INVALID_ENTITY_ID

  ecs::query(playerEid) <| $ [es] (
      var persistentSquadOrder_dot_orderType : int&;
      var persistentSquadOrder_dot_orderPosition : float3&;
      var persistentSquadOrder_dot_orderUseEntity : ecs::EntityId&)
    persistentSquadOrder_dot_orderType = squad_dot_orderType
    persistentSquadOrder_dot_orderPosition = squad_dot_orderPosition
    persistentSquadOrder_dot_orderUseEntity = squad_dot_orderUseEntity


[es (tag=server)]
def squad_persistent_order_es_event_handler(
    evt : RequestPersistentSquadOrder;
    eid : ecs::EntityId;
    squad_dot_leader : ecs::EntityId;
    var squad_dot_orderType : int&;
    var squad_dot_orderPosition : float3&;
    var squad_dot_orderUseEntity : ecs::EntityId&)

  var orderType : int = int(evt.orderType)

  if orderType == int(PersistentSquadOrder EPSO_CANCEL_ORDER)
    var playerEid = get_Eid(squad_dot_leader, "possessedByPlr") ?? INVALID_ENTITY_ID

    ecs::query(playerEid) <| $ [es] (
        persistentSquadOrder_dot_orderType : int;
        persistentSquadOrder_dot_orderPosition : float3 const&;
        persistentSquadOrder_dot_orderUseEntity : ecs::EntityId)

      if (persistentSquadOrder_dot_orderType == squad_dot_orderType)
        if (persistentSquadOrder_dot_orderUseEntity == squad_dot_orderUseEntity)
          if (distance_sq(persistentSquadOrder_dot_orderPosition, squad_dot_orderPosition) < 0.01f)
            squad_dot_orderType = int(SquadOrder ESO_FOLLOW_ME)
            squad_dot_orderPosition = float3()
            squad_dot_orderUseEntity = ecs::INVALID_ENTITY_ID

            squad_order_speech(eid, squad_dot_leader, squad_dot_orderType)

    store_persistent_squad_order(squad_dot_leader, int(SquadOrder ESO_FOLLOW_ME), float3(), ecs::INVALID_ENTITY_ID)
    return

  if orderType == int(PersistentSquadOrder EPSO_RALLY_AT_POINT)
    squad_dot_orderType = int(SquadOrder ESO_DEFEND_POINT)
    squad_dot_orderPosition = evt.orderPosition
    squad_dot_orderUseEntity = evt.orderUseEntity

    store_persistent_squad_order(squad_dot_leader, squad_dot_orderType, squad_dot_orderPosition, squad_dot_orderUseEntity)

    squad_order_speech(eid, squad_dot_leader, squad_dot_orderType)

