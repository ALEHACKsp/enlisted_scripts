require app
require ecs
require ecs.common
require DagorMath
require zones
require game.es.events
require game.utils.team
require DagorSystem
require game.es.battle_area_common
require net
require dm


def find_index_in_kill_list(killList : ecs::Array; visitor : EntityId)
  return find_index_if(killList) <| $ (elem) : bool
    let elemObj = get_ecs_object(elem)
    return elemObj != null && visitor == get_Eid(elemObj, "eid") ?? ecs::INVALID_ENTITY_ID


def is_in_next_active_battle_area(zonesIn : EidList; team : int)
  var found = false
  let curTime = get_sync_time()
  for zoneEid in zonesIn
    ecs::query(zoneEid) <| $ [es (REQUIRE=battle_area)] (battle_area_dot_deactivatedAtTime : float = -1.0;
                                                         battle_area_dot_timeToWarn : float = 0.0;
                                                         battle_area_dot_team : int = TEAM_UNASSIGNED)
      if battle_area_dot_team != TEAM_UNASSIGNED && team != battle_area_dot_team
        return
      if battle_area_dot_deactivatedAtTime < 0.0 || curTime < battle_area_dot_deactivatedAtTime + battle_area_dot_timeToWarn
        found = true
    if found
      break
  return found


def send_old_battle_area_event(eid : EntityId; zonesIn : EidList; team : int)
  let ett = typeinfo(undecorated_typename type<EventOnBorderOldBattleArea>)
  server_send_schemeless_event(eid, ett, eid) <| $ (var init : Object)
    set(init, "leaving", is_in_next_active_battle_area(zonesIn, team))

[generic]
def get_vehicle_time_to_damage(vehicleEid, timeByType, defTime)
  var vehicleTime: float const?
  if timeByType == null
    return defTime
  ecs::query(vehicleEid) <| $ [es] (battle_area_dot_timeToDamageType : string)
    vehicleTime = get_float(*timeByType, battle_area_dot_timeToDamageType)
  return vehicleTime ?? defTime

[generic]
def get_time_to_damage(timeType, timeByType, defTime)
  if timeType == null || timeByType == null
    return defTime
  return get_float(*timeByType, string(*timeType)) ?? defTime

[es (tag=server, REQUIRE=battle_area)]
def battle_area_zone_about_to_deactivate_es(evt : EventEntityAboutToDeactivate; var battle_area_dot_deactivatedAtTime : float&)
  battle_area_dot_deactivatedAtTime = get_sync_time()


[es (tag=server, REQUIRE=battle_area)]
def battle_area_zone_deactivate_es(evt : EventEntityActivate; var zone_dot_keepDead : bool&)
  let activate = get_bool(evt.data, "activate") ?? false
  if activate == false
    zone_dot_keepDead = false


[es (tag=server, no_order)]
def old_battle_area_warning_es(info : UpdateStageInfoAct; battle_area_dot_deactivatedAtTime : float; battle_area_dot_timeToWarn : float)
  if battle_area_dot_deactivatedAtTime >= 0.0
    let timeFromWarnStart = info.curTime - (battle_area_dot_deactivatedAtTime + battle_area_dot_timeToWarn)
    if timeFromWarnStart >= 0.0 && timeFromWarnStart <= info.dt
      ecs::query() <| $ [es] (eid : EntityId; battle_areas_visitor_dot_zonesIn: EidList; team : int)
        send_old_battle_area_event(eid, battle_areas_visitor_dot_zonesIn, team)

[es (tag=server, after=after_net_phys_sync)]
def battle_areas_visitor_update_es(info : UpdateStageInfoAct;
                                   eid : EntityId;
                                   transform : float3x4;
                               var battle_areas_visitor_dot_zonesIn : EidList;
                                   battle_areas_visitor_dot_updateInterval : float;
                               var battle_areas_visitor_dot_nextUpdateAt : float&;
                               var isOutsideBattleArea : bool&;
                                   zones_visitor_dot_triggerTag : string;
                                   team : int = TEAM_UNASSIGNED;
                                   beh_tree_dot_enabled : bool = false;
                                   battle_area_dot_timeToDamageType : das_string?;
                                   human_anim_dot_vehicleSelected : ecs::EntityId = INVALID_ENTITY_ID)
  if info.curTime < battle_areas_visitor_dot_nextUpdateAt
    return
  let updateTimeOveflow = info.curTime - battle_areas_visitor_dot_nextUpdateAt
  if updateTimeOveflow < battle_areas_visitor_dot_updateInterval
    battle_areas_visitor_dot_nextUpdateAt += battle_areas_visitor_dot_updateInterval
  else // either initial update, huge dt or small interval
    battle_areas_visitor_dot_nextUpdateAt = info.curTime + battle_areas_visitor_dot_updateInterval * eid_unit(eid)

  var curAreas : array<EntityId>
  reserve(curAreas, 1)
  query_active_battle_areas(transform[3], team, zones_visitor_dot_triggerTag) <| $(area_eid)
    push(curAreas, area_eid)
  let zonesInLen = length(battle_areas_visitor_dot_zonesIn)
  let nCurAreas = length(curAreas)
  if zonesInLen == nCurAreas
    return // not changed
  elif zonesInLen == 0 // return to battle area
    isOutsideBattleArea = false
    let ett = typeinfo(undecorated_typename type<EventOnBorderBattleArea>)
    server_send_schemeless_event(eid, ett, eid) <| $ (var init : Object)
      set(init, "leaving", false)
    ecs::find_query() <| $ [es] (var battle_area_dot_killList : ecs::Array) // remove from kill list
      let idx = find_index_in_kill_list(battle_area_dot_killList, eid)
      if idx >= 0
        erase(battle_area_dot_killList, idx)
        return true // found
      else
        return false
  elif nCurAreas == 0 // go outside of battle areas
    print("Entity left the battle area eid={eid} pos={transform[3]} beh_tree={beh_tree_dot_enabled}")
    isOutsideBattleArea = true
    let ett = typeinfo(undecorated_typename type<EventOnBorderBattleArea>)
    server_send_schemeless_event(eid, ett, eid) <| $ (var init : Object)
      set(init, "leaving", true)
    ecs::query(battle_areas_visitor_dot_zonesIn[0]) <| $ [es] (var battle_area_dot_killList : ecs::Array; // put to kill list
                                                               battle_area_dot_timeToDamage : float;
                                                               battle_area_dot_timeToDamageByType : ecs::Object?)
      let defaultTime = battle_area_dot_timeToDamage
      let timeByType  = battle_area_dot_timeToDamageByType
      let visitorType = battle_area_dot_timeToDamageType
      var timeToDamage = get_time_to_damage(visitorType, timeByType, defaultTime)
      timeToDamage     = get_vehicle_time_to_damage(human_anim_dot_vehicleSelected, timeByType, timeToDamage)
      push_object_to_array(battle_area_dot_killList) <| $ (var obj : Object)
        set(obj, "eid", eid)
        set(obj, "timer", timeToDamage)

  resize(battle_areas_visitor_dot_zonesIn, nCurAreas)
  for i in range(nCurAreas)
    battle_areas_visitor_dot_zonesIn[i] = curAreas[i]

  send_old_battle_area_event(eid, battle_areas_visitor_dot_zonesIn, team)


[es (tag=server, no_order)]
def battle_area_damage_es(info : UpdateStageInfoAct;
                          eid : EntityId;
                      var battle_area_dot_lastDamageAtTime : float&;
                      var battle_area_dot_killList : ecs::Array;
                          battle_area_dot_damage : float;
                          battle_area_dot_damageInterval : float = 1.0;
                          transform : float3x4)
  let dt = info.curTime - battle_area_dot_lastDamageAtTime
  if dt < battle_area_dot_damageInterval
    return
  battle_area_dot_lastDamageAtTime += battle_area_dot_damageInterval

  for elem in battle_area_dot_killList
    var elemObj = getRW_ecs_object(elem)
    if elemObj != null
      var victimTimer = getRW_float(*elemObj, "timer")
      if victimTimer != null
        *victimTimer -= dt
        if *victimTimer > 0.0
          continue
        let victimEid = get_Eid(*elemObj, "eid") ?? ecs::INVALID_ENTITY_ID
        let damageDesc = DamageDesc(DamageType DM_ZONE, battle_area_dot_damage, transform[3])
        damage_entity(victimEid, eid, damageDesc)

[es (tag=server, on_event=EventLevelLoaded, REQUIRE=battle_area, REQUIRE=humanTriggerable)]
def human_battle_area_check_es(evt: Event; eid : EntityId)
  var bad = false
  find_query() <| $ [es] (level_dot_fixedBattleAreas : bool; level_dot_navAreas: EidList)
    if level_dot_fixedBattleAreas
      bad = true;
      for navAreaEid in level_dot_navAreas
        if navAreaEid == eid
          bad = false
          break
      return bad
    return false
  if bad
    logerr("This level is using fixed human battle areas, entity {eid} should be created before level entity in {get_current_scene()}")
