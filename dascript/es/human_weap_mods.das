require ecs
require net
require app
require game.es.events
require DagorMath
require EnlistedWeapon

def human_weap_mod_activate(eid : EntityId;
                            human_weap_dot_gunEids: EidList;
                            human_weap_dot_gunMods: EidList;
                            human_weap_dot_reloadFinishTime : float;
                            var human_weap_dot_weapModActivateStartTime : float&;
                            var human_weap_dot_weapModActivateFinishTime : float&;
                            slot_id : int;
                            activate : bool)
  verify(is_server())
  if slot_id < 0 || slot_id >= length(human_weap_dot_gunMods)
    return
  let curTime = get_sync_time()
  let inProgress = curTime <= human_weap_dot_weapModActivateFinishTime
  if inProgress
    return
  if !human_weap_can_reload(eid, human_weap_dot_gunEids[slot_id]) || (human_weap_dot_reloadFinishTime > curTime)
    return
  ecs::query(human_weap_dot_gunMods[slot_id]) <| $ [es](weapon_mod_dot_active: bool;
                                                        weapon_mod_dot_activateTime : float;
                                                        weapon_mod_dot_deactivateTime : float)
    if (weapon_mod_dot_active == activate)
      return
    human_weap_dot_weapModActivateStartTime = curTime
    human_weap_dot_weapModActivateFinishTime = curTime + (activate ? weapon_mod_dot_activateTime : weapon_mod_dot_deactivateTime)

[es]
def human_weap_mod_toggle_es_event_handler(evt : CmdWeapModToggle; eid : EntityId; human_weap_dot_gunMods: EidList)
  if evt.slotId < 0 || evt.slotId >= length(human_weap_dot_gunMods)
    return
  ecs::query(human_weap_dot_gunMods[evt.slotId]) <| $ [es](weapon_mod_dot_active: bool)
    sendEvent(eid, [[CmdWeapModActivate slotId=evt.slotId, activate=!weapon_mod_dot_active]])

[es(tag=server, before=net_phys_update_es, before=human_weap_update_es)]
def human_weap_mod_active_update_es(info : UpdateStageInfoAct;
                                    human_weap_dot_gunMods: EidList;
                                    human_weap_dot_currentGunSlot : int;
                                    var human_weap_dot_weapModActivateStartTime : float&;
                                    var human_weap_dot_weapModActivateFinishTime : float&)
  if (human_weap_dot_weapModActivateStartTime < 0.0f) || (human_weap_dot_currentGunSlot < 0)
    return
  let inProgress = info.curTime <= human_weap_dot_weapModActivateFinishTime
  if inProgress
    return
  ecs::query(human_weap_dot_gunMods[human_weap_dot_currentGunSlot]) <| $ [es](var weapon_mod_dot_active: bool&)
    weapon_mod_dot_active = !weapon_mod_dot_active
    human_weap_dot_weapModActivateStartTime = -1.0f
    human_weap_dot_weapModActivateFinishTime = -1.0f

[es]
def human_weap_mod_activate_es_event_handler(evt : CmdWeapModActivate;
                                             eid : EntityId;
                                             human_weap_dot_gunEids: EidList;
                                             human_weap_dot_gunMods: EidList;
                                             human_weap_dot_reloadFinishTime : float;
                                             var human_weap_dot_weapModActivateStartTime : float&;
                                             var human_weap_dot_weapModActivateFinishTime : float&)
  if !is_server()
    sendEvent(eid, [[HumanRequestModActivate slotId=evt.slotId, activate=evt.activate]])
  else
    human_weap_mod_activate(eid, human_weap_dot_gunEids, human_weap_dot_gunMods, human_weap_dot_reloadFinishTime,
      human_weap_dot_weapModActivateStartTime, human_weap_dot_weapModActivateFinishTime,
      evt.slotId, evt.activate)

[es(tag=server)]
def human_weap_mod_activate_req_es_event_handler(evt : HumanRequestModActivate;
                                                eid : EntityId;
                                                human_weap_dot_gunEids: EidList;
                                                human_weap_dot_gunMods: EidList;
                                                human_weap_dot_reloadFinishTime : float;
                                                var human_weap_dot_weapModActivateStartTime : float&;
                                                var human_weap_dot_weapModActivateFinishTime : float&)
  human_weap_mod_activate(eid, human_weap_dot_gunEids, human_weap_dot_gunMods, human_weap_dot_reloadFinishTime,
    human_weap_dot_weapModActivateStartTime, human_weap_dot_weapModActivateFinishTime,
    evt.slotId, evt.activate)
