require enlisted.game.es.fortifications_build_common
require enlisted.game.es.enlisted_events
require game.es.events
require DagorSystem
require DagorMath
require math.base
require vehicle
require AnimV20
require ecs

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server)]
def building_set_time_on_create_es(evt: Event; var building_destroy_dot_timeToDestroy :float&; building_destroy_dot_maxTimeToDestroy:float)
  building_destroy_dot_timeToDestroy = building_destroy_dot_maxTimeToDestroy

[es (tag=server, no_order)]
def building_reset_destruction_timer_es(info: UpdateStageInfoAct;
                                        building_destroy_dot_maxTimeToDestroy:float;
                                        building_destroy_dot_timeToResetDestructionTimer: float;
                                        var building_destroy_dot_lastDamageAtTime: float&;
                                        var building_destroy_dot_timeToDestroy :float&)
  if building_destroy_dot_lastDamageAtTime == -1.f
    return
  if info.curTime - building_destroy_dot_lastDamageAtTime > building_destroy_dot_timeToResetDestructionTimer
    building_destroy_dot_timeToDestroy = building_destroy_dot_maxTimeToDestroy
    building_destroy_dot_lastDamageAtTime = -1.f

def isVehicleEmpty(vehicleEid : EntityId)
  var vehicleEmpty = true
  query(vehicleEid) <| $[es](vehicle_seats_owners: VehicleSeatsOwners)
    let owners & = vehicle_seats_owners.data
    for owner in owners
      if owner.eid != ecs::INVALID_ENTITY_ID
        vehicleEmpty = false
        break
  return vehicleEmpty

[es (tag=server, no_order)]
def destroyable_fortification_building_object(info: UpdateStageInfoAct;
                                              eid: EntityId;
                                              building_action_dot_target: EntityId;
                                              transform: float3x4;
                                              enter_vehicle_dot_atTime: float;
                                              human_use_object_dot_useDist: float;
                                              human_weap_dot_gunEids: ecs::EidList;
                                              building_action_dot_updateInterval: float;
                                              var building_action_dot_lastActionAtTime: float&)
  if !building_action_dot_target || building_action_dot_lastActionAtTime + building_action_dot_updateInterval > info.curTime
    return
  if building_action_dot_lastActionAtTime == -1.0
    building_action_dot_lastActionAtTime = info.curTime
    return
  let operatorEid = eid
  if enter_vehicle_dot_atTime > 0.f
    sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
  let operatorPos = transform[3]
  query(building_action_dot_target) <| $[es](eid: EntityId;
                                             transform: float3x4;
                                             var building_destroy_dot_timeToDestroy: float&;
                                             var building_destroy_dot_lastDamageAtTime: float&)
    if length_sq(transform[3]-operatorPos) > square(human_use_object_dot_useDist)
      sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return
    let buildingSpeedMul = get_engineer_building_speed_mul(human_weap_dot_gunEids)
    building_destroy_dot_timeToDestroy -= (info.curTime - building_action_dot_lastActionAtTime) * buildingSpeedMul
    building_destroy_dot_lastDamageAtTime = info.curTime
    building_action_dot_lastActionAtTime = info.curTime
    if building_destroy_dot_timeToDestroy < 0.f
      sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      if !isVehicleEmpty(eid)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_destroy_with_crew", text="building_blocked_destroy_with_crew"]])
        return
      destroyEntity(eid)

[es (tag=server)]
def dismantle_preview(evt : EventDismantleBuilding; eid : EntityId; isAlive : bool; isDowned : bool;
                      human_weap_dot_mortarMode : bool = false;
                      human_weap_dot_radioMode : bool = false)
  if !isAlive || isDowned || human_weap_dot_mortarMode || human_weap_dot_radioMode
    return
  if has(evt.target, "builder_server_preview")
    if !!get_player_eid_interacting_building(evt.target, eid)
      sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_destroy_during_build", text="building_blocked_destroy_during_build"]])
      return
    destroyEntity(evt.target)
  else
    sendEventImmediate(eid, [[EventSetBuildingTarget target=evt.target]])