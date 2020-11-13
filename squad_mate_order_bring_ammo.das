require ecs
require ecs.common
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
require HumanPhys
require EnlistedWeapon
require DaWeaponProps
require player
require app
require net
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq


def order_ammo(squad_eid, squad_dot_leader : ecs::EntityId; squad_dot_numAliveMembers : int) : bool
  var ordered = false
  let nearestTeammate = get_nearest_squad_mate_for_order(squad_eid, squad_dot_leader, SquadMateOrder ESMO_BRING_AMMO)
  if nearestTeammate.executeOrder
    return true
  if nearestTeammate.eid != INVALID_ENTITY_ID
    ecs::query(nearestTeammate.eid) <| $ [es] (var squad_member_dot_orderType : int&;
                                          var squad_member_dot_orderPosition : float3&;
                                          var squad_member_dot_orderUseEntity : ecs::EntityId&; var walker_agent : EntityAgent)
      walker_agent.blackBoard |> datablock_setInt("ammoRequester", int(uint(squad_dot_leader)))
      squad_member_dot_orderType = int(SquadMateOrder ESMO_BRING_AMMO)
      squad_member_dot_orderPosition = float3()
      squad_member_dot_orderUseEntity = INVALID_ENTITY_ID
      sendEvent(nearestTeammate.eid, [[CmdRequestHumanSpeech phrase=sound_hash("confirmResponseDelayed"), threshold=1.]])
      ordered = true
  if !ordered
    if squad_dot_numAliveMembers <= 1
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])
      send_order_cancel_bq(squad_dot_leader, "no_alive_squadmates", "{SquadMateOrder ESMO_BRING_AMMO}")
    else
      sendEvent(squad_dot_leader, [[CmdHeroLogEvent event="squad_order_canceled", text="ammo_order/no_ammo"]])
      send_order_cancel_bq(squad_dot_leader, "no_ammo", "{SquadMateOrder ESMO_BRING_AMMO}")
  else
    query(nearestTeammate.eid) <| $[es](transform : float3x4)
      send_squad_member_accept_order_bq(squad_dot_leader, "{SquadMateOrder ESMO_BRING_AMMO}", transform[3], true)
  return ordered

[es(tag=server)]
def on_squad_mate_bring_ammo_order(evt:RequestSquadMateOrder; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId;
                                  squad_dot_isLeaderNeedsAmmo : bool; squad_dot_numAliveMembers : int)
  if evt.orderType == SquadMateOrder ESMO_BRING_AMMO && squad_dot_isLeaderNeedsAmmo
    let requestAmmoAllowTime = get_float(squad_dot_leader, "requestAmmoAllowTime") ?? 0f
    if requestAmmoAllowTime > get_sync_time()
      server_send_schemeless_event(squad_dot_leader, typeinfo(undecorated_typename type<CmdHeroLogExEvent>), squad_dot_leader) <| $ (var init:Object)
        set(init, "_event", "squad_order_canceled")
        set(init, "_key", "msg/canRequestIn")
        set(init, "time", int(requestAmmoAllowTime - get_sync_time()))
    else
      order_ammo(eid, squad_dot_leader, squad_dot_numAliveMembers)

[es (on_event=EventEntityDied, tag=server)]
def on_squad_mate_bring_ammo_died_es(evt:Event; eid : EntityId; squad_member_dot_squad : ecs::EntityId; squad_member_dot_orderType : int;
                                    squad_dot_isLeaderNeedsAmmo : bool; squad_dot_numAliveMembers : int)
  if squad_member_dot_orderType == int(SquadMateOrder ESMO_BRING_AMMO) && squad_dot_isLeaderNeedsAmmo
    send_order_cancel_bq(eid, "died", "{SquadMateOrder ESMO_BRING_AMMO}")
    ecs::query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId)
      order_ammo(squad_member_dot_squad, squad_dot_leader, squad_dot_numAliveMembers)

[es(tag=server, no_order)]
def on_squad_mate_bring_ammo_es(act : ecs::UpdateStageInfoAct; squad_member_dot_squad : ecs::EntityId;
                                     var walker_agent : EntityAgent; var squad_member_dot_orderType : int&;
                                     var squad_member_dot_orderPosition : float3&; var squad_member_dot_orderUseEntity : ecs::EntityId&)
  if squad_member_dot_orderType != int(SquadMateOrder ESMO_BRING_AMMO)
    return
  ecs::query(squad_member_dot_squad) <| $[es] (squad_dot_leader : ecs::EntityId)
    if walker_agent.blackBoard |> datablock_getInt("ammoRequester", 0) != int(uint(squad_dot_leader))
      reset_squad_mate_order(squad_member_dot_orderType, squad_member_dot_orderPosition, squad_member_dot_orderUseEntity)
      walker_agent.blackBoard |> datablock_setInt("ammoRequester", 0)

[es (tag=server)]
def squad_mate_order_bring_ammo_es_event_handler(evt : RequestSquadMateOrder; squad_dot_leader : ecs::EntityId)
  if evt.orderType == SquadMateOrder ESMO_BRING_AMMO
    sendEvent(squad_dot_leader, [[CmdRequestHumanSpeech phrase=sound_hash("squadBringAmmoOrder"), threshold=1.]])

def can_fit_another_magazine(item_container; ammo_props_id; max_magazines)
  var magazines = 0
  for itemEid in item_container
    if !!itemEid && (get_int(itemEid, "item.ammoPropsId") ?? -1) == ammo_props_id
      if ++magazines >= max_magazines
        break
  return magazines < max_magazines

struct LeaderAmmoState
  isNeedsAmmo : bool = false
  hasSpaceForMagazine : bool = true
  isCompatibleWeapon : bool = true

def apply_ammo_state(squad_eid : EntityId; state : LeaderAmmoState)
  query(squad_eid) <| $[es] (var squad_dot_isLeaderNeedsAmmo : bool&;
                             var order_ammo_dot_hasSpaceForMagazine : bool&;
                             var order_ammo_dot_isCompatibleWeapon : bool&)
    squad_dot_isLeaderNeedsAmmo = state.isNeedsAmmo
    order_ammo_dot_hasSpaceForMagazine = state.hasSpaceForMagazine
    order_ammo_dot_isCompatibleWeapon = state.isCompatibleWeapon

def apply_ammo_state_server(squad_eid : EntityId; state : LeaderAmmoState)
  query(squad_eid) <| $[es] (var squad_dot_isLeaderNeedsAmmo : bool&)
    squad_dot_isLeaderNeedsAmmo = state.isNeedsAmmo

def get_squad_leader_ammo_state(isInVehicle : bool;
                                human_weap_dot_weapInfo : Array;
                                human_weap_dot_gunEids : EidList;
                                human_weap_dot_reserveAmmoPropIds : IntList;
                                itemContainer : EidList)
  var res = LeaderAmmoState()
  if isInVehicle
    res.isNeedsAmmo = false
    return res

  let slot = int(HUWeaponSlots EWS_PRIMARY)

  let gunEid = human_weap_dot_gunEids[slot]
  if !gunEid
    res.isNeedsAmmo = false
    return res

  let reserveAmmoPropsId = human_weap_dot_reserveAmmoPropIds[slot]
  if reserveAmmoPropsId < 0
    res.isCompatibleWeapon = false
    res.isNeedsAmmo = false
    return res

  query(gunEid) <| $ [es] (gun_dot_serverAmmo : int = 0;
                            gun_dot_totalAmmo : int = 0;
                            gun_dot_ammo_prop_ids : IntList;
                            gun_dot_requestAmmoThreshold : float = 0.10;
                            gun_dot_propsId : int = -1;
                            gun_dot_reloadable : bool = false)
    let magazineSize = get_ammo_props(reserveAmmoPropsId)?.maxShells ?? 0
    let weapInfo = get_ecs_object(human_weap_dot_weapInfo[slot])
    let maxMagazines = get_int(weapInfo, "numReserveAmmo") ?? 0
    let reserveMaxShots = maxMagazines * magazineSize
    let shots = gun_dot_totalAmmo + gun_dot_serverAmmo
    res.isCompatibleWeapon = find_index(gun_dot_ammo_prop_ids, reserveAmmoPropsId) >= 0 && gun_dot_propsId >= 0 && gun_dot_reloadable
    res.isNeedsAmmo = res.isCompatibleWeapon && float(shots) < gun_dot_requestAmmoThreshold * float(reserveMaxShots)
    if !res.isNeedsAmmo
      return

    res.hasSpaceForMagazine = can_fit_another_magazine(itemContainer, reserveAmmoPropsId, maxMagazines - (gun_dot_serverAmmo > 0 ? 1 : 0))
    res.isNeedsAmmo &&= res.hasSpaceForMagazine
  return res


[es (tag=server, track=(human_weap_dot_gunEids, isInVehicle, possessedByPlr))]
def squad_leader_needs_ammo_server(evt : Event;
                                   possessedByPlr : EntityId;
                                   isInVehicle : bool;
                                   squad_member_dot_squad : EntityId;
                                   human_weap_dot_weapInfo : Array;
                                   human_weap_dot_gunEids : EidList;
                                   human_weap_dot_reserveAmmoPropIds : IntList;
                                   itemContainer : EidList)
  if !!possessedByPlr
    let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap_dot_weapInfo, human_weap_dot_gunEids, human_weap_dot_reserveAmmoPropIds, itemContainer)
    apply_ammo_state_server(squad_member_dot_squad, ammoState)

[es (tag=server, track=(gun_dot_serverAmmo, ammo_holder_dot_ammoPropsId, gun_dot_totalAmmo),
  REQUIRE=(gun_dot_serverAmmo, ammo_holder_dot_ammoPropsId, gun_dot_totalAmmo))]
def squad_leader_gun_needs_ammo_server(evt : Event; gun_dot_owner : EntityId)
  query(gun_dot_owner) <| $[es] (possessedByPlr : EntityId;
                                 isInVehicle : bool;
                                 squad_member_dot_squad : EntityId;
                                 human_weap_dot_weapInfo : Array;
                                 human_weap_dot_gunEids : EidList;
                                 human_weap_dot_reserveAmmoPropIds : IntList;
                                 itemContainer :EidList)
    if !!possessedByPlr
      let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap_dot_weapInfo, human_weap_dot_gunEids, human_weap_dot_reserveAmmoPropIds, itemContainer)
      apply_ammo_state_server(squad_member_dot_squad, ammoState)

[es (tag=gameClient, REQUIRE=hero, on_event=EventComponentsAppear, track=(human_weap_dot_gunEids, isInVehicle))]
def squad_leader_needs_ammo_client(evt : Event;
                                   isInVehicle : bool;
                                   squad_member_dot_squad : EntityId;
                                   human_weap_dot_weapInfo : Array;
                                   human_weap_dot_gunEids : EidList;
                                   human_weap_dot_reserveAmmoPropIds : IntList;
                                   itemContainer : EidList)
  let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap_dot_weapInfo, human_weap_dot_gunEids, human_weap_dot_reserveAmmoPropIds, itemContainer)
  apply_ammo_state(squad_member_dot_squad, ammoState)

[es (tag=gameClient, track=(gun_dot_serverAmmo, ammo_holder_dot_ammoPropsId, gun_dot_totalAmmo),
  REQUIRE=(gun_dot_serverAmmo, ammo_holder_dot_ammoPropsId, gun_dot_totalAmmo))]
def squad_leader_gun_needs_ammo_client(evt : Event; gun_dot_owner : EntityId)
  query(gun_dot_owner) <| $[es(REQUIRE=hero)] (isInVehicle : bool;
                                               squad_member_dot_squad : EntityId;
                                               human_weap_dot_weapInfo : Array;
                                               human_weap_dot_gunEids : EidList;
                                               human_weap_dot_reserveAmmoPropIds : IntList;
                                               itemContainer : EidList)
    let ammoState = get_squad_leader_ammo_state(isInVehicle, human_weap_dot_weapInfo, human_weap_dot_gunEids, human_weap_dot_reserveAmmoPropIds, itemContainer)
    apply_ammo_state(squad_member_dot_squad, ammoState)
