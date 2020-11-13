require ecs
require app
require game.utils.team
require game.es.events
require enlisted.game.es.enlisted_events
require game.es.battle_area_common
require EnlistedWeapon
require HumanPhys
require EnlistedHuman
require zones
require EnlistedWalkerai
require game.es.sound.sound_events
require soundHash
require enlisted.game.es.artillery_radio_common
require DagorSystem

[es (tag=gameClient)]
def artillery_radio_device_state(evt : CmdSetDeviceState;
                                 human_weap_dot_gunEids : EidList;
                                 var human_net_phys : HumanActor)
  let curSlot = int(human_net_phys.phys.currentState.weapEquipState.curSlot)
  let isRadioReady = curSlot >= 0 && has(human_weap_dot_gunEids[curSlot], "radio_use")
  var ct& = human_net_phys.phys.producedCT
  let wasDeviceStateSet = ct.isDeviceStateSet
  human_control_state_set_device_state(ct, evt.enabled && (isRadioReady || wasDeviceStateSet));

[es (tag=(server,net), no_order)]
def artillery_radio_mode_server(info : UpdateStageInfoAct;
                                isAlive : bool;
                                isDowned : bool;
                                possessedByPlr : EntityId;
                                human_net_phys : HumanActor;
                                human_weap_dot_currentGunEid : EntityId;
                                var human_weap_dot_radioMode : bool&)
  human_weap_dot_radioMode = (human_net_phys.phys.appliedCT.isDeviceStateSet &&
                              isAlive && !isDowned &&
                              has(human_weap_dot_currentGunEid, "radio_use") && is_weapon_equipped(human_net_phys) &&
                              (!possessedByPlr || !is_artillery_on_cooldown(possessedByPlr)))

[es (tag=gameClient, REQUIRE=hero, no_order)]
def artillery_radio_mode_client(info : UpdateStageInfoAct;
                                eid : EntityId;
                                isAlive : bool;
                                isDowned : bool;
                                possessedByPlr : EntityId;
                                human_net_phys : HumanActor;
                                human_weap_dot_currentGunEid : EntityId;
                                var human_weap_dot_radioMode : bool&)
  var modeState = false
  let deviceInput = human_net_phys.phys.producedCT.isDeviceStateSet
  if deviceInput && isAlive && !isDowned && has(human_weap_dot_currentGunEid, "radio_use") && is_weapon_equipped(human_net_phys)
    if is_artillery_on_cooldown(possessedByPlr)
      send_schemeless_event(possessedByPlr, typeinfo(undecorated_typename type<CmdShowArtilleryCooldownHint>))
    else
      modeState = true
  human_weap_dot_radioMode = modeState
  if deviceInput && !human_weap_dot_radioMode
    sendEventImmediate(eid, [[CmdSetDeviceState enabled=false]])

[es (tag=gameClient, REQUIRE=radio_use)]
def radio_phys_update(evt : CmdWeapPhysUpdate;
                      eid : EntityId;
                      var radio_dot_selfOrder : bool&)
  if !evt.isForReal
    return

  var equipped = false;
  ecs::query(evt.owner) <| $ [es] (human_net_phys: HumanActor;
                                   human_weap_dot_currentGunEid : EntityId)
    equipped = human_weap_dot_currentGunEid == eid && is_weapon_equipped(human_net_phys)
  if !equipped
    return

  if radio_dot_selfOrder
    sendEventImmediate(evt.owner, [[CmdSetDeviceState enabled=true]])
    radio_dot_selfOrder = false

[es (tag=gameClient, track=human_weap_dot_radioMode, REQUIRE=hero)]
def radio_mode_change_on_client(evt:Event;
                                eid : ecs::EntityId;
                                var radioMode_dot_prevWeapon : int&;
                                human_weap_dot_currentGunEid : EntityId;
                                var radioMode_dot_prevPose : int&;
                                var human_net_phys: HumanActor;
                                human_weap_dot_radioMode : bool const)
  var ct& = human_net_phys.phys.producedCT
  if human_weap_dot_radioMode
    radioMode_dot_prevPose = human_input_get_stand_state(eid)
    human_input_set_stand_state(eid, int(HumanPhysControlType HCT_CROUCH))
  else
    if radioMode_dot_prevWeapon >= 0 && has(human_weap_dot_currentGunEid, "radio_use")
      set_chosen_weapon(ct, HUWeaponSlots(radioMode_dot_prevWeapon))
      radioMode_dot_prevWeapon = -1
    if radioMode_dot_prevPose >= 0
      human_input_set_stand_state(eid, radioMode_dot_prevPose)

[es (tag=server)]
def request_artillery_strike(evt : RequestArtilleryStrikeAtPos;
                             eid : ecs::EntityId;
                             team : int;
                             human_weap_dot_radioMode : bool;
                             squad_member_dot_squad : EntityId const)
  if !has_active_human_battle_area_at(evt.pos, team)
    return
  if human_weap_dot_radioMode
    let playerEid = get_Eid(evt.owner, "possessedByPlr") ?? INVALID_ENTITY_ID
    sendEvent(playerEid, [[CmdStartArtilleryStrikeAtPos owner=evt.owner, pos=evt.pos]])
    sendEvent(eid, [[CmdRequestHumanSpeech phrase=sound_hash("artStrikeStart"), threshold=1.]])
  else
    sendEventImmediate(squad_member_dot_squad, [[RequestArtilleryOverOrder active=true, targetPos=evt.pos]])

[es (tag=gameClient)]
def artillery_map_pos_selected(evt : EventArtilleryMapPosSelected;
                               team : int;
                               eid : ecs::EntityId)
  let pos = get_Point3(evt.data, "pos")
  if pos == null
    logerr("EventArtilleryMapPosSelected missing payload 'pos' with type Point3")
    return
  if has_active_human_battle_area_at(*pos, team)
    send_schemeless_event(eid, typeinfo(undecorated_typename type<CmdCloseArtilleryMap>))
    sendEvent(eid, [[CmdSetDeviceState enabled=false]])
    sendEvent(eid, [[RequestArtilleryStrikeAtPos owner=eid, pos=*pos]])

[es (tag=gameClient, on_event=RequestCloseArtilleryMap)]
def artillery_map_close_request(evt : Event;
                                squad_member_dot_squad : EntityId const;
                                eid : ecs::EntityId)
  send_schemeless_event(eid, typeinfo(undecorated_typename type<CmdCloseArtilleryMap>))
  sendEventImmediate(eid, [[CmdSetDeviceState enabled=false]])
  sendEvent(squad_member_dot_squad, [[RequestArtilleryOverOrder active=false, targetPos=float3()]])

[es (tag=gameClient, on_event=CmdArtillerySelfOrder)]
def radio_self_order_client_es(evt : Event;
                               human_weap_dot_gunEids : ecs::EidList const;
                               human_weap_dot_curGunSlot : int;
                               var radioMode_dot_prevWeapon : int&;
                               var human_net_phys: HumanActor)
  query(get_radio_eid(human_weap_dot_gunEids)) <| $[es](var radio_dot_selfOrder: bool&)
    if is_weapon_equipped(human_net_phys)
      radioMode_dot_prevWeapon = human_weap_dot_curGunSlot
    set_chosen_weapon(human_net_phys.phys.producedCT, HUWeaponSlots EWS_SECONDARY)
    radio_dot_selfOrder = true

[es (track=human_weap_dot_radioMode)]
def radio_animation_start_end_control(evt : Event;
                                      human_weap_dot_gunEids : ecs::EidList;
                                      human_weap_dot_curGunSlot : int;
                                      human_weap_dot_radioMode : bool)
  let weapEid = human_weap_dot_gunEids[human_weap_dot_curGunSlot]
  query(weapEid) <| $ [es (REQUIRE=radio_use)] (var device_animation_dot_isActive : bool&;
                                                var device_animation_dot_startAt : float&;
                                                var device_animation_dot_endAt : float&)
    if human_weap_dot_radioMode
      device_animation_dot_isActive = true
      device_animation_dot_startAt = get_sync_time()
    else
      device_animation_dot_endAt = get_sync_time()

[es (tag=gameClient, track=human_weap_dot_radioMode, REQUIRE=hero)]
def radio_mode_exit_close_map(evt : Event; eid : EntityId; human_weap_dot_radioMode : bool)
  if human_weap_dot_radioMode
    send_schemeless_event(eid, typeinfo(undecorated_typename type<CmdOpenArtilleryMap>))
  else
    send_schemeless_event(eid, typeinfo(undecorated_typename type<CmdCloseArtilleryMap>))
