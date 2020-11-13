require ecs
require ecs.common
require net
require vehicle
require game.utils.hero
require math
require math.base
require game.es.events
require game.es.events
require game.es.vehicle.vehicle_events
require AnimV20
require DagorSystem

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_seats_camera_nodes_init(evt: Event;
                                    eid: EntityId;
                                    animchar: AnimcharBaseComponent;
                                    [[shared_comp]] vehicle_seats_dot_seats: Array;
                                    var vehicle_seats_camera_nodes_dot_indices: IntList;
                                    var vehicle_seats_camera_nodes_dot_offsets: Point3List;
                                    var vehicle_seats_camera_nodes_dot_defaultNodeId: int&)
  let defaultNodeName = get_string(eid, "vehicle_seats_camera_nodes.defaultNode", "")
  let defaultNodeId = animchar_find_node_index(animchar, defaultNodeName)
  if defaultNodeId < 0
    logerr("Node {defaultNodeName} for camera not found, entity {eid} <{getEntityTemplateName(eid)}>")
    return
  vehicle_seats_camera_nodes_dot_defaultNodeId = defaultNodeId
  let seatsCount = length(vehicle_seats_dot_seats)
  resize(vehicle_seats_camera_nodes_dot_indices, seatsCount)
  resize(vehicle_seats_camera_nodes_dot_offsets, seatsCount)
  for seatNo in range(0, seatsCount)
    let seat = get_ecs_object(vehicle_seats_dot_seats[seatNo])
    let nodeName = get_string(seat, "cameraNodeName", "")
    let nodeId = nodeName != "" ? animchar_find_node_index(animchar, nodeName) : defaultNodeId
    if nodeId < 0
      logerr("Node {nodeName} for camera not found, entity {eid} <{getEntityTemplateName(eid)}>")
      return
    vehicle_seats_camera_nodes_dot_indices[seatNo] = nodeId
    vehicle_seats_camera_nodes_dot_offsets[seatNo] = get_Point3(seat, "cameraOffset") ?? float3()

let
  camera_type_names = [[auto
    "none";
    "passenger";
    "driver";
    "gunner";
    "gunner_cockpit";
    "commander";
    "commander_cockpit";
    "machinegunner_cockpit";
    "dead"
  ]]

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_seats_camera_types_init(evt: Event;
                                    [[shared_comp]] vehicle_seats_dot_seats: Array;
                                    [[shared_comp]] defaultCameraTypes: Object;
                                    var vehicle_seats_camera_types: IntList)
  assert(length(camera_type_names) == int(VehicleCameraType VEHICLE_CAMERA_NUM))
  let seatsCount = length(vehicle_seats_dot_seats)
  resize(vehicle_seats_camera_types, seatsCount)
  for seatNo in range(0, seatsCount)
    let seat = get_ecs_object(vehicle_seats_dot_seats[seatNo])
    var cameraTypeName = get_string(seat, "cameraType", "")
    if cameraTypeName == ""
      cameraTypeName = get_string(defaultCameraTypes, get_string(seat, "name", ""), "none")
    if cameraTypeName != ""
      let camera_type = find_index(camera_type_names, cameraTypeName)
      vehicle_seats_camera_types[seatNo] = camera_type >= 0 ? camera_type : int(VehicleCameraType VEHICLE_CAMERA_NONE)

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def vehicle_seats_player_camera_types_init(evt: Event;
                                           [[shared_comp]] vehicle_seats_dot_seats: Array;
                                           var vehicle_seats_player_camera_types: IntList)
  let seatsCount = length(vehicle_seats_dot_seats)
  resize(vehicle_seats_player_camera_types, seatsCount)
  for seatNo in range(0, seatsCount)
    vehicle_seats_player_camera_types[seatNo] = int(VehicleCameraType VEHICLE_CAMERA_NONE)

[es (tag=gameClient, track=vehicle_seats_owners, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventComponentChanged, on_event=EventHeroChanged)]
def vehicle_seats_update_animchar_camera_target(evt: Event;
                                                vehicle_seats_owners: VehicleSeatsOwners;
                                                vehicle_seats_camera_nodes_dot_indices: IntList;
                                                vehicle_seats_camera_nodes_dot_offsets: Point3List;
                                                var animchar_camera_target_dot_nodeIndex: int&;
                                                var animchar_camera_target_dot_node_offset: float3?)
  let hero = get_controlled_hero()
  if !hero
    return
  let owners & = vehicle_seats_owners.data
  for seatNo in iter_range(owners)
    if owners[seatNo].eid == hero
      animchar_camera_target_dot_nodeIndex = vehicle_seats_camera_nodes_dot_indices[seatNo]
      if animchar_camera_target_dot_node_offset != null
        *animchar_camera_target_dot_node_offset = vehicle_seats_camera_nodes_dot_offsets[seatNo]

[es (on_event=EventHeroChanged)]
def vehicle_camera_update(evt: Event; var shooter_cam_dot_alternative_settings: bool&)
  shooter_cam_dot_alternative_settings = false

[es (tag=gameClient, REQUIRE=heroVehicle, REQUIRE=camNames)]
def vehicle_seats_camera_init(info: UpdateStageInfoAct;
                              eid: EntityId;
                              vehicle_seats_owners: VehicleSeatsOwners;
                              var isCameraInited: bool&)
  if isCameraInited
    return
  let hero = get_controlled_hero()
  if !has(hero, "bindedCamera") // no hero or it's not observed yet
    return
  isCameraInited = true
  let owners & = vehicle_seats_owners.data
  for owner in owners
    if owner.eid == hero && owner.isPlayer
      sendEvent(owner.player, [[CmdSwitchCameraByEntity index=0, camNamesEid=eid]])
