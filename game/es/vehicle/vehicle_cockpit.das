require ecs
require ecs.common
require math
require math.base
require math.easing
require math.ang
require vehicle
require player
require AnimV20
require DagorMath
require DagorSystem
require DagorMath
require DagorMathUtils
require game.es.vehicle.vehicle_seats_common

let
  quat_ident = float4(0.f, 0.f, 0.f, 1.f)

[es (on_event=(EventEntityCreated, EventComponentsAppear, EventHeroChanged), track=(vehicle_seats_owners, vehicleCameraType, cockpit_dot_eid), tag=render, REQUIRE=(vehicleCameraType, heroVehicle, cockpit_dot_eid))]
def vehicle_change_cockpit_es(evt : Event;
                              eid : EntityId;
                              [[shared_comp]] vehicle_seats_dot_seats : Array;
                              vehicle_seats_owners : VehicleSeatsOwners;
                              vehicle_seats_camera_nodes_dot_indices : IntList;
                              vehicleCameraType: int;
                              var vehicle_sight_dot_opacity: float&)
  if (vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER) ||
      vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_DEAD))
    return

  let heroSeatIdx = vehicle_get_hero_seat_idx(vehicle_seats_owners)
  if heroSeatIdx < 0
    return

  let hasCockpit = find_query() <| $[es](cockpit_dot_vehicleEid: EntityId)
    return cockpit_dot_vehicleEid == eid

  if hasCockpit
    return

  let attachNodeIndex = vehicle_seats_camera_nodes_dot_indices[heroSeatIdx]
  if attachNodeIndex < 0
    return

  let seat = get_ecs_object(vehicle_seats_dot_seats[heroSeatIdx])
  let cockpitTemplate = get_string(seat, "cockpitTemplate", "")
  if cockpitTemplate == ""
    return

  vehicle_sight_dot_opacity = 0.f

  createEntitySync(cockpitTemplate) <| $ (var init : ComponentsInitializer)
    set(init, "cockpit.attachNodeIndex", attachNodeIndex)
    set(init, "cockpit.vehicleEid", eid)
    set(init, "cockpit.seatNo", heroSeatIdx)
    set(init, "cockpit.cameraTime", 1.f)
    set(init, "cockpit.zoomTime", 0.f)

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def cockpit_attach_nodes_init(evt: Event;
                              cockpit_dot_vehicleEid : EntityId;
                              cockpit_dot_attachNodeIndex : int;
                              cockpit_dot_attachNodeNames : StringList;
                              cockpit_dot_slitNodeNames: StringList;
                              var cockpit_dot_attachNodeIndices : IntList)
  ecs::query(cockpit_dot_vehicleEid) <| $ [es] (animchar: AnimcharBaseComponent)
    let slitNodesCount = length(cockpit_dot_slitNodeNames)
    let attachNodesCount = length(cockpit_dot_attachNodeNames)
    let commonNodesCount = min(slitNodesCount, attachNodesCount)
    resize(cockpit_dot_attachNodeIndices, slitNodesCount)
    for i in range(0, commonNodesCount)
      let nodeName = string(cockpit_dot_attachNodeNames[i])
      cockpit_dot_attachNodeIndices[i] = animchar_find_node_index(animchar, nodeName)
    for i in range(commonNodesCount, slitNodesCount)
      cockpit_dot_attachNodeIndices[i] = cockpit_dot_attachNodeIndex

[es (tag=gameClient, track=vehicle_seats_owners)]
def vehicle_is_cockpit_seat(evt : Event;
                            [[shared_comp]] vehicle_seats_dot_seats : Array;
                            vehicle_seats_owners : VehicleSeatsOwners;
                            var cockpit_dot_isHeroInCockpit : bool&)
  let heroSeatIdx = vehicle_get_hero_seat_idx(vehicle_seats_owners)
  if heroSeatIdx < 0
    cockpit_dot_isHeroInCockpit = false
    return
  let seat = get_ecs_object(vehicle_seats_dot_seats[heroSeatIdx])
  let cockpitTemplate = get_string(seat, "cockpitTemplate", "")
  cockpit_dot_isHeroInCockpit = cockpitTemplate != ""

[es (tag=render, after=animchar_es)]
def vehicle_attach_cockpit_es(info : UpdateStageInfoAct;
                              eid : EntityId;
                              var animchar_render_dot_enabled : bool&;
                              var transform : float3x4;
                              var cockpit_dot_isAttached: bool&;
                              var cockpit_dot_attachNodeIndex : int&;
                              cockpit_dot_attachNodeIndices : IntList?;
                              cockpit_dot_currentSlit: int;
                              cockpit_dot_cockpitOffsetBySlit: Point3List?;
                              cockpit_dot_offset : float3;
                              cockpit_dot_vehicleEid : EntityId;
                              cockpit_dot_seatNo: int;
                              cockpit_dot_angles: float3?)
  cockpit_dot_isAttached = false

  ecs::query(cockpit_dot_vehicleEid) <| $ [es] (animchar: AnimcharBaseComponent;
                                                vehicle_seats_owners: VehicleSeatsOwners;
                                                vehicleCameraType: int;
                                                isAlive, isExploded: bool)
    if !isAlive || isExploded
      return

    if (vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER) ||
        vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_DEAD))
      return

    let heroSeatNo = vehicle_get_hero_seat_idx(vehicle_seats_owners)
    if heroSeatNo < 0 || heroSeatNo != cockpit_dot_seatNo
      return

    if cockpit_dot_attachNodeIndices != null
      cockpit_dot_attachNodeIndex = (*cockpit_dot_attachNodeIndices)[cockpit_dot_currentSlit]
    cockpit_dot_isAttached = true

    var offset = cockpit_dot_offset
    if cockpit_dot_cockpitOffsetBySlit != null
      offset += (*cockpit_dot_cockpitOffsetBySlit)[cockpit_dot_currentSlit]

    animchar_get_node_wtm(animchar, cockpit_dot_attachNodeIndex, transform)
    transform[2] = -transform[2]
    transform[3] = transform * offset

    if cockpit_dot_angles != null
      transform = transform * make_rot_cw_zyx(*cockpit_dot_angles * DEG_TO_RAD)

  if !cockpit_dot_isAttached
    animchar_render_dot_enabled = false
    destroyEntity(eid)

[es (tag=render, track=cockpit_dot_isAttached)]
def vehicle_cockpit_slits_init(evt: Event;
                               eid : EntityId;
                               animchar: AnimcharBaseComponent;
                               cockpit_dot_isAttached: bool;
                               cockpit_dot_slitNodeNames: StringList;
                               cockpit_dot_slitAngles: FloatList?;
                               cockpit_dot_cockpitOffsetBySlit: Point3List?;
                               cockpit_dot_offset : float3;
                               transform : float3x4;
                               var cockpit_dot_slitNodes: IntList;
                               var cockpit_dot_slitCameraOffsets: Point3List;
                               var cockpit_dot_slitCameraDirs: Point3List)
  if !cockpit_dot_isAttached
    return

  let nodesCount = length(cockpit_dot_slitNodeNames)
  resize(cockpit_dot_slitNodes, nodesCount)
  resize(cockpit_dot_slitCameraOffsets, nodesCount)
  resize(cockpit_dot_slitCameraDirs, nodesCount)

  var cockpitTm := transform
  cockpitTm[2] = -cockpitTm[2]
  var cockpitItm = inverse(cockpitTm)

  for i in range(0, nodesCount)
    let slitNodeId = animchar_find_node_index(animchar, string(cockpit_dot_slitNodeNames[i]))
    cockpit_dot_slitNodes[i] = slitNodeId
    if slitNodeId < 0
      logerr("Cockpit node '{cockpit_dot_slitNodeNames[i]}' not found. Vehicle {eid} <{getEntityTemplateName(eid)}>")
      continue

    var slitNodeWtm: float3x4
    animchar_get_node_wtm(animchar, slitNodeId, slitNodeWtm)

    var offset = cockpit_dot_offset
    if cockpit_dot_cockpitOffsetBySlit != null
      offset += (*cockpit_dot_cockpitOffsetBySlit)[i]
    offset[2] = -offset[2]

    let slitRelToCockpitTm = cockpitItm * slitNodeWtm
    cockpit_dot_slitCameraOffsets[i] = slitRelToCockpitTm[3] + offset

    if cockpit_dot_slitAngles != null
      let angle = deg_to_rad((*cockpit_dot_slitAngles)[i])
      cockpit_dot_slitCameraDirs[i] = float3(cos(angle), 0.f, sin(angle))
    else
      var slitNodeTm: float3x4
      animchar_get_node_wtm(animchar, slitNodeId, slitNodeTm)
      slitNodeTm = cockpitItm * slitNodeTm
      cockpit_dot_slitCameraDirs[i] = normalize(slitNodeTm[0])

[es (tag=render, track=cockpit_dot_isAttached)]
def vehicle_cockpit_visible_nodes_init(evt: Event;
                                       eid : EntityId;
                                       cockpit_dot_isAttached: bool;
                                       cockpit_dot_vehicleEid: EntityId;
                                       cockpit_dot_visibleVehicleNodeNames: StringList;
                                       var cockpit_dot_wasVisibleVehicleNodes: BoolList;
                                       var cockpit_dot_visibleVehicleNodes: BoolList)
  if !cockpit_dot_isAttached
    return

  let nodesCount = length(cockpit_dot_visibleVehicleNodeNames)

  ecs::query(cockpit_dot_vehicleEid) <| $ [es] (animchar_render: AnimcharRendComponent)
    let renderNodesCount = animchar_render_get_nodes_count(animchar_render)
    resize(cockpit_dot_wasVisibleVehicleNodes, renderNodesCount)
    resize(cockpit_dot_visibleVehicleNodes, renderNodesCount)

    for nodeId in range(0, renderNodesCount)
      cockpit_dot_wasVisibleVehicleNodes[nodeId] = animchar_render_is_node_visible(animchar_render, nodeId)
      cockpit_dot_visibleVehicleNodes[nodeId] = false

    for i in range(0, nodesCount)
      let nodeId = animchar_render_get_node_name_id(animchar_render, string(cockpit_dot_visibleVehicleNodeNames[i]))
      if nodeId < 0
        logerr("Node '{nodeId}' not found in vehicle {eid} <{getEntityTemplateName(eid)}>")
        continue
      cockpit_dot_visibleVehicleNodes[nodeId] = true

def get_relative_to_slit_coords(pos : float3;
                                animchar : AnimcharBaseComponent;
                                cockpit_dot_attachNodeIndices : IntList?;
                                from_slit : int;
                                to_slit : int) : float3
  if cockpit_dot_attachNodeIndices == null
    return pos
  let node_from = (*cockpit_dot_attachNodeIndices)[from_slit]
  let node_to = (*cockpit_dot_attachNodeIndices)[to_slit]
  var fromTm, toTm : float3x4
  animchar_get_node_wtm(animchar, node_from, fromTm)
  fromTm[2] = -fromTm[2]
  animchar_get_node_wtm(animchar, node_to, toTm)
  toTm[2] = -toTm[2]
  return inverse(toTm) * fromTm * pos

[es (tag=render, track=cockpit_dot_nextSlit)]
def vehicle_cockpit_on_slit_change(evt: Event;
                                   cockpit_dot_prevSlit: int;
                                   cockpit_dot_nextSlit: int;
                                   cockpit_dot_slitCameraDirs: Point3List;
                                   cockpit_dot_slitCameraOffsets: Point3List;
                                   cockpit_dot_attachNodeIndices : IntList?;
                                   cockpit_dot_minZoom: float;
                                   cockpit_dot_vehicleEid: EntityId;
                                   var cockpit_dot_cameraTime: float&;
                                   var cockpit_dot_startCameraPos: float3&;
                                   var cockpit_dot_endCameraPos: float3&)

  let prevCameraOffset = cockpit_dot_slitCameraOffsets[cockpit_dot_prevSlit]
  let prevCameraDir    = cockpit_dot_slitCameraDirs[cockpit_dot_prevSlit]
  var prevOffset       = prevCameraDir * cockpit_dot_minZoom

  let cameraOffset = cockpit_dot_slitCameraOffsets[cockpit_dot_nextSlit]
  let cameraDir    = cockpit_dot_slitCameraDirs[cockpit_dot_nextSlit]
  let offset       = cameraDir * cockpit_dot_minZoom

  var endPos = cameraOffset + offset
  query(cockpit_dot_vehicleEid) <| $[es](animchar: AnimcharBaseComponent; var cockpit_dot_isGunner: bool&)
    cockpit_dot_isGunner = false
    endPos[2] = -endPos[2]
    endPos = get_relative_to_slit_coords(endPos, animchar, cockpit_dot_attachNodeIndices, cockpit_dot_nextSlit, cockpit_dot_prevSlit)
    endPos[2] = -endPos[2]

  cockpit_dot_startCameraPos = prevCameraOffset + prevOffset
  cockpit_dot_endCameraPos   = endPos
  cockpit_dot_cameraTime     = 0.f

def init_transition(camera_dir: float3; cockpit_tm: float3x4; owner_eid: EntityId; var start_dir: float3&; var end_orient: float4&)
  query(owner_eid) <| $[es](human_input_dot_aimAngle: float2)
    let endDir = rotate(cockpit_tm, camera_dir)
    start_dir = angles_to_dir(human_input_dot_aimAngle)
    end_orient = float4(quat_rotation_arc(start_dir, endDir))

def init_cockpit_transition(cur_attach_tm : float3x4;
                            next_attach_tm : float3x4;
                            var out_orient_x : float4&;
                            var out_orient_y : float4&)
  out_orient_x = float4(quat_rotation_arc(cur_attach_tm[0], next_attach_tm[0]))
  out_orient_y = float4(quat_rotation_arc(cur_attach_tm[1], next_attach_tm[1]))

def get_cockpit_offset_for_slit(cockpit_dot_offset : float3;
                                cockpit_dot_cockpitOffsetBySlit :Point3List?;
                                current_slit : int) : float3
  if cockpit_dot_cockpitOffsetBySlit == null
    return cockpit_dot_offset
  let currentPos = (*cockpit_dot_cockpitOffsetBySlit)[current_slit]
  return cockpit_dot_offset + currentPos

def get_cockpit_transition_offset(cockpit_dot_offset : float3;
                                  animchar: AnimcharBaseComponent;
                                  cockpit_dot_attachNodeIndices : IntList?;
                                  cockpit_dot_cockpitOffsetBySlit : Point3List?;
                                  current_slit : int;
                                  next_slit : int;
                                  t : float) : float3
  let fromPos = get_cockpit_offset_for_slit(cockpit_dot_offset, cockpit_dot_cockpitOffsetBySlit, current_slit)
  var toPos = get_cockpit_offset_for_slit(cockpit_dot_offset, cockpit_dot_cockpitOffsetBySlit, next_slit)
  toPos = get_relative_to_slit_coords(toPos, animchar, cockpit_dot_attachNodeIndices, next_slit, current_slit)
  return lerp(fromPos, toPos, float3(t))

def set_cockpit_transition_rotation(cockpit_dot_endOrientX: float4;
                                    cockpit_dot_endOrientY: float4;
                                    t : float;
                                    var in_out_tm : float3x4&)
  let cockpitQuatX = quat(normalize(lerp(quat_ident, cockpit_dot_endOrientX, float4(t))))
  let cockpitQuatY = quat(normalize(lerp(quat_ident, cockpit_dot_endOrientY, float4(t))))
  var x = cockpitQuatX * in_out_tm[0]
  let y = cockpitQuatY * in_out_tm[1]
  let z = cross(x, y)
  x = cross(y, z)
  in_out_tm[0] = x
  in_out_tm[1] = y
  in_out_tm[2] = z

[es (tag=render, after=(vehicle_cockpit_slits,vehicle_attach_cockpit_es), before=animchar_cam_target__with_offset_es)]
def vehicle_cockpit_slits_transition(info: UpdateStageInfoAct;
                                     cockpit_dot_seatNo: int;
                                     cockpit_dot_attachNodeIndex: int;
                                     cockpit_dot_startCameraPos: float3;
                                     cockpit_dot_endCameraPos: float3;
                                     cockpit_dot_vehicleEid: EntityId;
                                     cockpit_dot_nextSlit: int;
                                     cockpit_dot_slitCameraDirs: Point3List;
                                     cockpit_dot_cockpitOffsetBySlit: Point3List?;
                                     cockpit_dot_attachNodeIndices : IntList?;
                                     cockpit_dot_offset : float3;
                                     var transform : float3x4;
                                     var cockpit_dot_startCameraDir: float3&;
                                     var cockpit_dot_endCameraOrient: float4&;
                                     var cockpit_dot_endOrientX: float4&;
                                     var cockpit_dot_endOrientY: float4&;
                                     var cockpit_dot_currentSlit: int&;
                                     var cockpit_dot_zoomTime: float&;
                                     var cockpit_dot_cameraTime: float&;
                                     cockpit_dot_zoomTimeMul = 1.f;
                                     cockpit_dot_cameraTimeMul = 1.f)
  let inTransition = cockpit_dot_cameraTime < 1.f

  let wasInZoom = cockpit_dot_zoomTime > 0.f
  cockpit_dot_zoomTime = saturate(cockpit_dot_zoomTime + (inTransition ? -info.dt : info.dt) * cockpit_dot_zoomTimeMul)

  let inZoom = cockpit_dot_zoomTime > 0.f
  if inZoom
    return

  if !inTransition
    return

  cockpit_dot_cameraTime += info.dt * cockpit_dot_cameraTimeMul

  ecs::query(cockpit_dot_vehicleEid) <| $ [es] (animchar: AnimcharBaseComponent; vehicle_seats_owners: VehicleSeatsOwners; var animchar_camera_target_dot_node_offset: float3&; var cockpit_dot_cameraDir: float3&)
    animchar_get_node_wtm(animchar, cockpit_dot_attachNodeIndex, transform)

    if wasInZoom
      let cameraDir = cockpit_dot_slitCameraDirs[cockpit_dot_nextSlit]
      var nextAttachTm : float3x4
      if cockpit_dot_attachNodeIndices != null
        animchar_get_node_wtm(animchar, (*cockpit_dot_attachNodeIndices)[cockpit_dot_nextSlit], nextAttachTm)
        init_cockpit_transition(transform, nextAttachTm, cockpit_dot_endOrientX, cockpit_dot_endOrientY)
      let cockpitTm& = cockpit_dot_attachNodeIndices != null ? nextAttachTm : transform
      init_transition(cameraDir, cockpitTm, vehicle_seats_owners.data[cockpit_dot_seatNo].eid,
                      cockpit_dot_startCameraDir, cockpit_dot_endCameraOrient)

    let t = saturate(inOutSine(cockpit_dot_cameraTime))
    let q = quat(normalize(lerp(quat_ident, cockpit_dot_endCameraOrient, float4(t))))
    cockpit_dot_cameraDir = q * cockpit_dot_startCameraDir
    animchar_camera_target_dot_node_offset = lerp(cockpit_dot_startCameraPos, cockpit_dot_endCameraPos, float3(t))

    transform[2] = -transform[2]
    transform[3] = transform * get_cockpit_transition_offset(cockpit_dot_offset, animchar, cockpit_dot_attachNodeIndices, cockpit_dot_cockpitOffsetBySlit,
                                                             cockpit_dot_currentSlit, cockpit_dot_nextSlit, t)
    if cockpit_dot_attachNodeIndices != null
      set_cockpit_transition_rotation(cockpit_dot_endOrientX, cockpit_dot_endOrientY, t, transform)

    let humanInCockpit & = vehicle_seats_owners.data[cockpit_dot_seatNo]
    query(humanInCockpit.eid) <| $[es](var human_input_dot_aimAngle: float2&)
      human_input_dot_aimAngle = dir_to_angles(cockpit_dot_cameraDir)

  if cockpit_dot_cameraTime >= 1.0f
    cockpit_dot_currentSlit = cockpit_dot_nextSlit

[es (tag=render, after=(animchar_es,vehicle_attach_cockpit_es), before=animchar_cam_target__with_offset_es)]
def vehicle_cockpit_slits(info: UpdateStageInfoAct;
                          cockpit_dot_isAttached: bool;
                          cockpit_dot_zoomTime: float;
                          cockpit_dot_minZoom: float;
                          cockpit_dot_attachNodeIndex: int;
                          cockpit_dot_vehicleEid: EntityId;
                          cockpit_dot_currentSlit: int;
                          cockpit_dot_slitNodes: IntList;
                          cockpit_dot_slitForwardOffset: FloatList;
                          cockpit_dot_slitCameraOffsets: Point3List;
                          cockpit_dot_slitCameraDirs: Point3List;
                          var cockpit_dot_zoom: float&)
  if !cockpit_dot_isAttached || cockpit_dot_currentSlit >= length(cockpit_dot_slitNodes)
    return

  let nodeId = cockpit_dot_slitNodes[cockpit_dot_currentSlit]
  if nodeId < 0
    return

  let t = inOutSine(cockpit_dot_zoomTime)
  let zoom = lerp(cockpit_dot_minZoom, cockpit_dot_slitForwardOffset[cockpit_dot_currentSlit], t)
  cockpit_dot_zoom = zoom

  let cameraOffset = cockpit_dot_slitCameraOffsets[cockpit_dot_currentSlit]
  let cameraDir    = cockpit_dot_slitCameraDirs[cockpit_dot_currentSlit]
  let offset       = cameraDir * zoom

  ecs::query(cockpit_dot_vehicleEid) <| $ [es] (animchar: AnimcharBaseComponent;
                                                var vehicle_sight_dot_opacity: float&;
                                                var animchar_camera_target_dot_node_offset: float3&;
                                                var animchar_camera_target_dot_nodeIndex: int&;
                                                var cockpit_dot_cameraDir: float3&)
    animchar_camera_target_dot_nodeIndex = cockpit_dot_attachNodeIndex
    animchar_camera_target_dot_node_offset = cameraOffset + offset

    var cockpitTm: float3x4
    animchar_get_node_wtm(animchar, cockpit_dot_attachNodeIndex, cockpitTm)

    cockpit_dot_cameraDir = rotate(cockpitTm, cameraDir)

    vehicle_sight_dot_opacity = inQuintic(cockpit_dot_zoomTime)

[private]
def set_cockpit_eid_to_vehicle_impl(eid, cockpit_dot_vehicleEid: EntityId)
  ecs::query(cockpit_dot_vehicleEid) <| $ [es] (var cockpit_dot_eid: EntityId&)
    cockpit_dot_eid = eid

[es (tag=gameClient, on_event=EventEntityCreated)]
def set_cockpit_eid_to_vehicle(evt: Event; eid, cockpit_dot_vehicleEid: EntityId)
  set_cockpit_eid_to_vehicle_impl(eid, cockpit_dot_vehicleEid)

[es (tag=gameClient, on_event=EventEntityDestroyed)]
def reset_cockpit_eid_to_vehicle(evt: Event; cockpit_dot_vehicleEid: EntityId)
  set_cockpit_eid_to_vehicle_impl(INVALID_ENTITY_ID, cockpit_dot_vehicleEid)
