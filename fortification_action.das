require enlisted.game.es.enlisted_events
require game.es.events
require DagorMathUtils
require math.base
require AnimV20
require ecs

def update_building_preview_colors(selectedObject: EntityId; builderPos: float3; isEngineer: bool; engineer_team: int)
  query() <| $[es (REQUIRE_NOT=builder_additive_preview)](eid: EntityId;
                   transform: float3x4;
                   visibleDistance: float;
                   selectedPlacingColor: float3;
                   enemyPlacingColor: float3;
                   previewTeam: int;
                   previewColor: float3;
                   var semi_transparent_dot_placingColor: float3&;
                   var semi_transparent_dot_visible: bool&)
    if eid == selectedObject
      semi_transparent_dot_visible = true
      if previewTeam == engineer_team
        semi_transparent_dot_placingColor = selectedPlacingColor
      return
    if !isEngineer && has(eid, "onlyForEngineer")
      semi_transparent_dot_visible = false
      return
    let distane = length(transform[3] - builderPos)
    if distane > visibleDistance
      semi_transparent_dot_visible = false
      return;
    semi_transparent_dot_visible = true
    let colorCoef = 1.0 - distane / visibleDistance
    if previewTeam != engineer_team
      semi_transparent_dot_placingColor = enemyPlacingColor * colorCoef
      return
    semi_transparent_dot_placingColor = previewColor * colorCoef

def find_preview_impl(eid, isEngineer, center, radius, traceFrom, traceTo)
  let onlyForEngineer = has(eid, "onlyForEngineer")
  var isPreviewFound  = !onlyForEngineer || isEngineer
  if isPreviewFound
    let isOnLineOfSight = test_segment_sphere_intersection(traceFrom, traceTo, center, square(radius))
    isPreviewFound &&= isOnLineOfSight
  return isPreviewFound ? eid : INVALID_ENTITY_ID

def find_server_preview(isEngineer, traceFrom, traceTo)
  var previewEid = INVALID_ENTITY_ID
  find_query() <| $[es (REQUIRE_NOT=builder_additive_preview, REQUIRE=builder_server_preview)](eid: EntityId; transform: float3x4; buildingRadius: float)
    previewEid = find_preview_impl(eid, isEngineer, transform[3], buildingRadius, traceFrom, traceTo)
    return !!previewEid
  return previewEid

def find_destroyable_buildings(isEngineer, traceFrom, traceTo)
  var previewEid = INVALID_ENTITY_ID
  find_query() <| $[es (REQUIRE_NOT=(builder_additive_preview, builder_server_preview))](eid: EntityId; transform: float3x4; buildingRadius: float)
    previewEid = find_preview_impl(eid, isEngineer, transform[3], buildingRadius, traceFrom, traceTo)
    return !!previewEid
  return previewEid

[es (tag=gameClient, REQUIRE=input_dot_enabled, after=hero_human_use_human_object_es, after=hero_human_use_stationary_gun_object_es)]
def find_bilding_action_target(info: UpdateStageInfoAct;
                               bindedCamera: EntityId;
                               team: int;
                               human_weap_dot_currentGunEid: EntityId;
                               human_use_object_dot_nodeId: int;
                               human_use_object_dot_useDist: float;
                               animchar: AnimcharBaseComponent;
                               input_dot_enabled: bool;
                               isInVehicle: bool = false;
                               var human_use_object_dot_selectedObject: EntityId&)
  if !input_dot_enabled || isInVehicle || human_use_object_dot_selectedObject != INVALID_ENTITY_ID
    return
  let camTmRef = get_TMatrix(bindedCamera, "transform")
  if camTmRef == null
    return
  let camTm = *camTmRef
  let traceDir: float3 = camTm[2]
  let tracePos: float3 = (human_use_object_dot_nodeId > 0
    ? animchar_get_node_wpos(animchar, human_use_object_dot_nodeId)
    : camTm[3])
  let endOfTrace = tracePos + traceDir * human_use_object_dot_useDist
  let isEngineer = has(human_weap_dot_currentGunEid, "previewEid")
  human_use_object_dot_selectedObject = find_server_preview(isEngineer, tracePos, endOfTrace)
  if !human_use_object_dot_selectedObject
    human_use_object_dot_selectedObject = find_destroyable_buildings(isEngineer, tracePos, endOfTrace)
  update_building_preview_colors(human_use_object_dot_selectedObject, camTm[3], isEngineer, team)

[es (tag=server, track=(isAlive,isDowned,human_weap_dot_mortarMode,human_weap_dot_radioMode), REQUIRE=building_action_dot_target)]
def building_action_reset_on_die(evt: Event;
                                 eid: EntityId;
                                 isAlive : bool;
                                 isDowned : bool;
                                 human_weap_dot_mortarMode : bool;
                                 human_weap_dot_radioMode : bool)
  if !isAlive || isDowned || human_weap_dot_mortarMode || human_weap_dot_radioMode
    sendEvent(eid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])

[es (tag=server, track=building_action_dot_target)]
def building_action_reset_timer(evt: Event;
                             building_action_dot_target: EntityId;
                             var building_action_dot_lastActionAtTime: float&)
  if building_action_dot_target == INVALID_ENTITY_ID
    building_action_dot_lastActionAtTime=-1.0

[es (tag=server, REQUIRE=human_use_object_dot_selectedObject, after=vehicle_seats_es_event_handler)]
def building_action_net_start(evt: EventSetBuildingTarget;
                              isAlive: bool;
                              var building_action_dot_target: EntityId&)
  building_action_dot_target = isAlive ? evt.target : INVALID_ENTITY_ID