require ecs
require ecs.common
require net
require vehicle
require player
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events
require AnimV20
require CollRes
require DagorSystem

[es (tag=gameClient, REQUIRE=input_dot_enabled, no_order)]
def find_maintainable_object(info: UpdateStageInfoAct;
                             eid: EntityId;
                             bindedCamera: EntityId;
                             var maintenance_dot_target: EntityId&;
                             var maintenance_dot_hasTarget: bool&;
                             human_use_object_dot_nodeId: int;
                             human_use_object_dot_useDist: float;
                             animchar: AnimcharBaseComponent;
                             input_dot_enabled: bool;
                             isInVehicle: bool = false)
  if !input_dot_enabled || isInVehicle
    return
  let camTmRef = get_TMatrix(bindedCamera, "transform")
  if camTmRef == null
    return
  let camTm = *camTmRef
  let traceDir: float3 = camTm[2]
  let tracePos: float3 = (human_use_object_dot_nodeId > 0
    ? animchar_get_node_wpos(animchar, human_use_object_dot_nodeId)
    : camTm[3])
  var t = human_use_object_dot_useDist
  maintenance_dot_target = INVALID_ENTITY_ID
  let operatorEid = eid
  find_query() <| $[es](eid: EntityId;
                        collres: CollisionResource;
                        transform: float3x4;
                        animchar: AnimcharBaseComponent;
                        maintainable_dot_operator: EntityId)
    var norm: float3
    if (maintainable_dot_operator == operatorEid ||
      (maintainable_dot_operator == INVALID_ENTITY_ID &&
        collres_traceray(collres, transform, animchar, tracePos, traceDir, t, norm)))
      maintenance_dot_target = eid
      return true
    return false
  maintenance_dot_hasTarget = maintenance_dot_target != INVALID_ENTITY_ID

[es (tag=gameClient)]
def find_maintainable_object_event(evt: EventEnterVehicle;
                                   var maintenance_dot_target: EntityId&;
                                   var maintenance_dot_hasTarget: bool&)
  maintenance_dot_target = INVALID_ENTITY_ID
  maintenance_dot_hasTarget = false

[es (tag=server, REQUIRE=maintenance_dot_target)]
def maintenance_net_start(evt: RequestStartMaintenance; eid: EntityId)
  sendEvent(eid, [[CmdStartMaintenance target=evt.target]])

[es (tag=server, REQUIRE=maintenance_dot_target)]
def maintenance_net_stop(evt: RequestStopMaintenance; eid: EntityId)
  sendEvent(eid, [[CmdStopMaintenance target=evt.target]])

[es (tag=gameClient, REQUIRE=replication)]
def request_start_maintenance_client(evt: CmdStartMaintenance; eid: EntityId; isInVehicle: bool)
  if isInVehicle
    return
  sendEvent(eid, [[RequestStartMaintenance target=evt.target]])

[es (tag=gameClient, REQUIRE=replication)]
def request_stop_maintenance_client(evt: CmdStopMaintenance; eid: EntityId)
  sendEvent(eid, [[RequestStopMaintenance target=evt.target]])

[es (tag=server)]
def maintenance_dispatcher_start(evt: CmdStartMaintenance;
                                 eid: EntityId;
                                 var maintenance_dot_target: EntityId&;
                                 repair_dot_hasRepairKit: bool = true)
  maintenance_dot_target = evt.target
  if !repair_dot_hasRepairKit
    return
  let isBurn = get_bool(maintenance_dot_target, "fire_damage.isBurn") ?? false
  if isBurn
    sendEvent(eid, [[CmdActivateExtinguisher eid=maintenance_dot_target]])
    return
  let isNeedRepair = get_bool(maintenance_dot_target, "repairable.repairRequired") ?? false
  if isNeedRepair && repair_dot_hasRepairKit
    sendEvent(eid, [[CmdStartRepair target=maintenance_dot_target]])

[es (tag=server)]
def maintenance_dispatcher_stop(evt: CmdStopMaintenance;
                                eid: EntityId;
                                maintenance_dot_target: EntityId;
                                extinguisher_dot_active: bool = false;
                                repair_dot_active: bool = false)
  if extinguisher_dot_active
    sendEvent(eid, [[CmdStopExtinguisher eid=maintenance_dot_target]])
  elif repair_dot_active
    sendEvent(eid, [[CmdStopRepair target=maintenance_dot_target]])
