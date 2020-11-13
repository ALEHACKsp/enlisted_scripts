require enlisted.game.es.fortifications_build_common
require enlisted.game.es.enlisted_events
require game.es.battle_area_common
require game.utils.hero
require game.utils.team
require DagorMathUtils
require game.es.events
require EnlistedHuman
require DagorSystem
require ecs.common
require math.base
require DagorMath
require PhysVars
require RendInst
require CollRes
require Dacoll
require zones
require math
require ecs
require app

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def building_preview_collobj_init_es(evt: Event;
                                     ri_preview_dot_name: das_string?;
                                     previewCollres: CollisionResource?;
                                     preview_phys_dot_blk: string;
                                     var previewCollobj: CollisionObject)
  var baseCollres = get_building_collres(previewCollres, ri_preview_dot_name)
  if baseCollres != null
    add_dynamic_collision_from_coll_resource(previewCollobj, *baseCollres, preview_phys_dot_blk)

[es (on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def building_preview_collobj_cleanup_es(evt: Event; var previewCollobj: CollisionObject)
  destroy_dynamic_collision(previewCollobj)

def is_pitch_in_range(vec, limits)
  let angle = 90.0 - rad_to_deg(dir_to_angles(vec).y)
  return angle > limits.x && angle < limits.y

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), before=building_preview_inactive_destroyes_es)]
def building_preview_destroy_timer_create_es(evt: Event;
                                             destroyInactiveTimeOut: float;
                                             var destroyByInactiveShredderAtTime: float&)
  destroyByInactiveShredderAtTime = get_sync_time() + destroyInactiveTimeOut

[es (tag=gameClient, before=build_ability_update_transform_es)]
def building_preview_rendinst_create_es(info: UpdateStageInfoAct;
                                        ri_preview_dot_name: string;
                                        var buildingBoxMin:float3&;
                                        var buildingBoxMax:float3&)
  if length_sq(buildingBoxMax - buildingBoxMin) > 0.f
    return;
  let resIndex = get_rigen_extra_res_idx(ri_preview_dot_name)
  let resBox = riex_get_lbb(resIndex)
  buildingBoxMin = resBox.bmin.xyz
  buildingBoxMax = resBox.bmax.xyz

[es ( tag=gameClient, before=build_ability_update_transform_es)]
def building_preview_animchar_create_es(info: UpdateStageInfoAct;
                                        animchar_bbox : bbox3f;
                                        nextCheckGridObjectsTime: float;
                                        var buildingBoxMin:float3&;
                                        transform: float3x4;
                                        var buildingBoxMax:float3&)
  if  get_sync_time() < nextCheckGridObjectsTime
    return
  buildingBoxMin = animchar_bbox.bmin.xyz - transform[3]
  buildingBoxMax = animchar_bbox.bmax.xyz - transform[3]

[es (tag=gameClient, no_order, REQUIRE=builder_preview, REQUIRE_NOT=(builder_server_preview, builder_additive_preview))]
def build_ability_update_transform_es(info: UpdateStageInfoAct;
                                      eid: EntityId;
                                      avaliableAngles: float2;
                                      avaliableColor: float3;
                                      blockedColor: float3;
                                      buildingDistance: float;
                                      additionalHeight: float;
                                      additionalYawRotation : float?;
                                      buildingBoxMin : float3;
                                      buildingBoxMax : float3;
                                      checkGridObjectsTimeInterval: float;
                                      building_builder_dot_minDistanceToRespawns = -1.0;
                                      building_builder_dot_minDistanceToCapturePoints = -1.0;
                                      ri_preview_dot_name: das_string?;
                                      previewCollres: CollisionResource?;
                                      previewCollobj: CollisionObject;
                                      previewCollobjOffset: float;
                                      var buildingNorm: float3&;
                                      var nextCheckGridObjectsTime: float&;
                                      var transform: float3x4;
                                      var semi_transparent_dot_placingColor: float3&;
                                      var semi_transparent_dot_visible: bool&)
  let hero = get_controlled_hero()
  var norm : float3
  var build_position : float3
  var isAngleValid = true
  var aimTm: float3x4;
  var availableByCountLimit = true
  var heroTeam = TEAM_UNASSIGNED
  ecs::query(hero) <| $ [es]  (human_dot_aimTm: float3x4;
                               human_use_object_dot_selectedObject: EntityId;
                               human_weap_dot_currentGunEid: EntityId;
                               possessedByPlr: EntityId;
                               team : int = TEAM_UNASSIGNED)
    heroTeam = team
    if has(human_use_object_dot_selectedObject, "builder_server_preview")
      semi_transparent_dot_visible = false
      return
    let previewId = get_int(human_weap_dot_currentGunEid, "currentPreviewId") ?? -1
    availableByCountLimit = count_available_buildings_by_type(possessedByPlr, previewId) != 0
    semi_transparent_dot_visible = true
    var traceDir = human_dot_aimTm[0]
    var tracePos = human_dot_aimTm[3]
    var len = buildingDistance
    var height = 100.0
    let traceAdditionEps = float3(0.0, 0.05, 0.0)
    traceray_normalized(tracePos, traceDir, len, norm)
    build_position = tracePos + traceDir * len
    if length(norm) == 0.f
      if !tracedown_normalized(build_position + traceAdditionEps, height, norm, ETF_DEFAULT)
        return
      build_position.y -= height
    build_position.y += additionalHeight
    buildingNorm = norm
    isAngleValid = is_pitch_in_range(norm, avaliableAngles)
    aimTm = human_dot_aimTm
  if !semi_transparent_dot_visible || length_sq(aimTm[0]) == 0.f
    return
  if length_sq(norm) == 0.f
    norm = float3(0.f, 1.f, 0.f)
  if isAngleValid
    transform[1] = norm
  transform[0] = normalize(cross(transform[1], aimTm[2]))
  if additionalYawRotation != null
    transform[0] = quat(norm, deg_to_rad(*additionalYawRotation)) * transform[0]
  transform[2] = normalize(cross(transform[0], transform[1]))
  transform[3] = build_position
  let syncTime = get_sync_time()
  if syncTime > nextCheckGridObjectsTime
    var baseCollres = get_building_collres(previewCollres, ri_preview_dot_name)
    let buildPos = build_position
    let minDistanceToCapturePoints = building_builder_dot_minDistanceToCapturePoints
    let minDistanceToRespawns = building_builder_dot_minDistanceToRespawns
    let isValid = (isAngleValid &&
                   availableByCountLimit &&
                   is_distance_to_capture_points_valid(buildPos, minDistanceToCapturePoints) &&
                   !find_respawn_eid_for_team_in_radius(buildPos, minDistanceToRespawns, eid, heroTeam) &&
                   !is_conflict_objects_in_building_box(transform, BBox3(buildingBoxMin, buildingBoxMax), previewCollobj,
                     previewCollobjOffset, eid, baseCollres) &&
                   has_active_human_battle_area_at(buildPos, heroTeam) &&
                   !is_not_attachable_gun(eid))
    semi_transparent_dot_placingColor = isValid ? avaliableColor : blockedColor
    nextCheckGridObjectsTime = syncTime + checkGridObjectsTimeInterval

def get_verified_fortification_template_name(templateName, fortificationTm, builderPos, notificationEid)
  let tpl = getTemplateByName(templateName)
  if tpl == null
    logerr("template {templateName} doesn't exist")
    return ""
  let anglesComp = getTemplateComponent(tpl, "avaliableAngles")
  if anglesComp == null
    logerr("Angle limits aren't specified in template {templateName}")
    return ""
  let avaliableAngles = get_Point2(anglesComp) ?? float2()
  let norm = fortificationTm[1]
  if !is_pitch_in_range(norm, avaliableAngles)
    return ""
  let buildingDistance = get_float(getTemplateComponent(tpl, "buildingDistance")) ?? 0.0
  var buildingPosForVerification = fortificationTm[3]
  buildingPosForVerification.y = builderPos.y
  let distance = length(builderPos - buildingPosForVerification)
  let eps = 1.0
  if distance > buildingDistance + eps // When moving, positions on client and on server are different
    sendEvent(notificationEid, [[CmdHeroLogEvent event="building_blocked_by_distance", text="building_blocked_by_distance"]])
    return ""
  let instantiateComp = getTemplateComponent(tpl, "instantiateTemplate")
  if instantiateComp == null
    logerr("instantiateTemplate isn't specified in template {templateName}")
    return ""
  return get_string(instantiateComp, "")

def count_available_buildings_by_type(plrEid, currentPreviewId)
  var buildingsByType = -1
  if currentPreviewId >= 0
    ecs::query(plrEid) <| $ [es] (availableBuildings: IntList)
      if currentPreviewId < length(availableBuildings)
        buildingsByType = availableBuildings[currentPreviewId]
  return buildingsByType

[es (tag=server, track=gun_dot_owner, on_event=(EventEntityCreated,EventComponentsAppear))]
def init_available_buildings_es(evt : Event;
                                gun_dot_owner : EntityId;
                                buildingLimits : IntList)
  query(gun_dot_owner) <| $[es](possessedByPlr : EntityId;
                                squad_member_dot_squad : EntityId = INVALID_ENTITY_ID)
    let player = (!!possessedByPlr ? possessedByPlr : get_Eid(squad_member_dot_squad, "squad.ownerPlayer") ?? INVALID_ENTITY_ID)
    query(player) <| $ [es] (var availableBuildings: IntList)
      if length(availableBuildings) != 0
        return
      resize(availableBuildings, length(buildingLimits))
      for i in iter_range(buildingLimits)
        availableBuildings[i] = buildingLimits[i]

[es (tag=server)]
def build_fortification_es(evt: CmdBuildFortification;
                           eid: ecs::EntityId;
                           human_dot_aimTm: float3x4;
                           human_weap_dot_currentGunEid: ecs::EntityId;
                           team: int;
                           possessedByPlr: ecs::EntityId)
  if human_weap_dot_currentGunEid != evt.builderGunEid
    return
  let previewTm = evt.tm
  let buildingBox = BBox3(evt.boxMin, evt.boxMax)
  if !has_active_human_battle_area_at(previewTm[3], team)
    sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_outside_battle_area", text="building_blocked_outside_battle_area"]])
    return
  let curTime = get_sync_time()
  ecs::query(human_weap_dot_currentGunEid) <| $ [es] (previewTemplate: StringList;
                                                      additionalBuildingTemplate: string;
                                                      currentPreviewId: int;
                                                      buildingInterval: float;
                                                      minBuildingRadius: float;
                                                      var nextBuildingAtTime: float&)
    if nextBuildingAtTime > curTime
      sendEvent(eid, [[CmdHeroLogEvent event="building_blocked_by_time", text="building_blocked_by_time"]])
      return
    let fortificationTemplate = get_verified_fortification_template_name(string(previewTemplate[currentPreviewId]), previewTm, human_dot_aimTm[3], eid)
    if fortificationTemplate == ""
      return
    let count = count_available_buildings_by_type(possessedByPlr, currentPreviewId)
    if count == 0
      return
    nextBuildingAtTime = curTime + buildingInterval
    let buildingRadius = max(length(evt.boxMax - evt.boxMin) * 0.5, minBuildingRadius)
    createEntity("{additionalBuildingTemplate}+{previewTemplate[currentPreviewId]}") <| $ (var init: ComponentsInitializer)
      set(init, "transform", previewTm)
      set(init, "buildingRadius", buildingRadius)
      set(init, "buildTypeId", currentPreviewId)
      set(init, "previewTeam", team)
      set(init, "buildByPlayer", possessedByPlr)

[es (tag=server)]
def next_building_type_es(evt : CmdNextBuildingType; previewTemplate: StringList; var currentPreviewId : int&)
  currentPreviewId = (currentPreviewId + 1) % length(previewTemplate)

[es (tag=server)]
def select_building_type_es(evt : CmdSelectBuildingType; previewTemplate: StringList; var currentPreviewId : int&)
  let index = get_int(evt.data, "index")
  if index == null
    logerr("Received CmdSelectBuildingType event missing payload 'index'")
  elif *index < length(previewTemplate)
    currentPreviewId = *index
  else
    logerr("Trying to select building type out of previewTemplate's range ({*index} [0..{length(previewTemplate)}])")

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=gameClient)]
def animvars_for_building_preview_es(evt: Event; var phys_vars : PhysVars; previewAnimVarParams: StringList; previewAnimVarParamsValue: FloatList)
  for paramNo in iter_range(previewAnimVarParams)
    let paramId = register_var(phys_vars, string(previewAnimVarParams[paramNo]), 0.0)
    set_var(phys_vars, paramId, previewAnimVarParamsValue[paramNo])

def changeBuildingLimits(playerEid, buildTypeId, count)
  ecs::query(playerEid) <| $ [es] (var availableBuildings: IntList)
    availableBuildings[buildTypeId]+=count

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server)]
def building_create_es(evt: Event; buildTypeId: int; buildByPlayer: ecs::EntityId)
  changeBuildingLimits(buildByPlayer, buildTypeId, -1)

[es (on_event=EventEntityDestroyed, tag=server)]
def building_destroyed_es(evt: Event; buildTypeId: int; buildByPlayer: ecs::EntityId)
  changeBuildingLimits(buildByPlayer, buildTypeId, 1)

[es (on_event=EventEntityDied, tag=server)]
def building_died_es(evt: Event; buildTypeId: int; var buildByPlayer: ecs::EntityId&)
  changeBuildingLimits(buildByPlayer, buildTypeId, 1)
  buildByPlayer = INVALID_ENTITY_ID

[es (tag=gameClient, track=currentPreviewId, REQUIRE=currentPreviewId)]
def hero_change_build_id_es(evt:Event;
                            gun_dot_owner: ecs::EntityId)
  let hero = get_controlled_hero()
  if hero != gun_dot_owner
    return
  sendEvent(gun_dot_owner, [[EventRecreateBuildPreview]])

[es (tag=gameClient, on_event="enlisted_events::EventTryBuildFortification", after=build_ability_update_transform_es, REQUIRE=builder_preview)]
def try_build_fortification_es(evt: Event;
                               eid: EntityId;
                               transform: float3x4;
                               avaliableAngles: float2;
                               buildingNorm: float3;
                               builderGunEid : ecs::EntityId;
                               buildingBoxMin : float3;
                               buildingBoxMax : float3;
                               building_builder_dot_minDistanceToRespawns = -1.0;
                               building_builder_dot_minDistanceToCapturePoints = -1.0;
                               previewCollres: CollisionResource?;
                               ri_preview_dot_name: das_string?;
                               previewCollobj: CollisionObject;
                               previewCollobjOffset: float)
  let hero = get_controlled_hero()
  var actionWithObj = INVALID_ENTITY_ID
  var equipped = false
  var heroTeam = TEAM_UNASSIGNED
  ecs::query(hero) <| $ [es] (human_net_phys: HumanActor; building_action_dot_target: EntityId; team = TEAM_UNASSIGNED)
    equipped = is_weapon_equipped(human_net_phys)
    actionWithObj = building_action_dot_target
    heroTeam = team
  if !equipped || actionWithObj != INVALID_ENTITY_ID
    return
  if !is_pitch_in_range(buildingNorm, avaliableAngles)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_by_angle", text="building_blocked_by_angle"]])
    return
  var baseCollres = get_building_collres(previewCollres, ri_preview_dot_name)
  if is_conflict_objects_in_building_box(transform, BBox3(buildingBoxMin, buildingBoxMax), previewCollobj, previewCollobjOffset, eid, baseCollres)
    sendEvent(hero, [[CmdHeroLogEvent event="building_cannot_confirm_when_objects_in", text="building_cannot_confirm_when_objects_in"]])
    return
  if is_not_attachable_gun(eid)
    sendEvent(hero, [[CmdHeroLogEvent event="building_gun_not_attachable", text="building_gun_not_attachable"]])
    return
  let buildingPos = transform[3]
  let nearestRespawnObject = find_respawn_eid_for_team_in_radius(buildingPos, building_builder_dot_minDistanceToRespawns, eid, heroTeam)
  if !!nearestRespawnObject
    respawns_distance_error_notify_player(hero, nearestRespawnObject)
    return
  if !is_distance_to_capture_points_valid(buildingPos, building_builder_dot_minDistanceToCapturePoints)
    sendEvent(hero, [[CmdHeroLogEvent event="building_blocked_too_close_to_capture_points", text="building_blocked_too_close_to_capture_points"]])
    return
  sendEvent(hero, [[CmdBuildFortification builderGunEid = builderGunEid,
                                          tm = transform,
                                          boxMin = buildingBoxMin,
                                          boxMax = buildingBoxMax]])

[es (tag=gameClient, REQUIRE=hero)]
def hero_change_build_es(evt:EventHeroChanged)
  sendEvent(evt.eid, [[EventRecreateBuildPreview]])

[es (tag=gameClient, track=human_weap_dot_currentGunEid, REQUIRE=(hero, human_weap_dot_currentGunEid))]
def hero_weapon_changed_build_es(evt: Event; eid : ecs::EntityId)
  sendEvent(eid, [[EventRecreateBuildPreview]])

[es (tag=gameClient)]
def select_build_tool_on_client(evt: EventRecreateBuildPreview; human_weap_dot_currentGunEid: ecs::EntityId)
  ecs::query() <| $[es(REQUIRE=builder_preview, REQUIRE_NOT=builder_server_preview)](eid : ecs::EntityId)
    destroyEntity(eid)
  ecs::query(human_weap_dot_currentGunEid) <| $ [es] (var previewEid: ecs::EntityId&; previewTemplate: StringList; currentPreviewId: int)
    previewEid = createEntity(string(previewTemplate[currentPreviewId])) <| $ (var init: ComponentsInitializer)
      set(init, "builderGunEid", human_weap_dot_currentGunEid)

def build_fortification_immediately(owner: EntityId; isShootPressed: bool)
  var buildingNow = false;
  ecs::query(owner) <| $ [es] (human_use_object_dot_selectedObject: EntityId;
                               building_action_dot_target:EntityId)
    let selectBuilding = has(human_use_object_dot_selectedObject, "builder_server_preview")
    if selectBuilding
      buildingNow = true
      if isShootPressed
        if building_action_dot_target != INVALID_ENTITY_ID
          return
        sendEvent(owner, [[EventSetBuildingTarget target = human_use_object_dot_selectedObject]])
        return
  return buildingNow

[es (tag=gameClient)]
def start_build_fortification_es(evt: CmdWeapPhysUpdate;
                                 previewEid: ecs::EntityId;
                                 autoTryBuildingObjectInterval: float;
                                 var nextTryToSetObjectInTime: float&;
                                 var builder_dot_shootPressed: bool&)
  if !evt.isForReal
    return
  let isShootPressed = evt.gctrl.shoot
  if !previewEid
    return
  let curTime = get_sync_time()
  if isShootPressed && !builder_dot_shootPressed && nextTryToSetObjectInTime < curTime
    nextTryToSetObjectInTime = curTime + autoTryBuildingObjectInterval
    sendEvent(previewEid, [[EventTryBuildFortification]])
  elif !isShootPressed
    builder_dot_shootPressed = false
    nextTryToSetObjectInTime = -1.0


[es (tag=gameClient, before=start_build_fortification_es)]
def start_building_action_fortification_es(evt: CmdWeapPhysUpdate;
                                           var builder_dot_shootPressed: bool&)
  if !evt.isForReal
    return
  let isShootPressed = evt.gctrl.shoot
  var buildPreviewWasStarted = false
  let canTryStartBuilding = isShootPressed != builder_dot_shootPressed
  if canTryStartBuilding
    if !isShootPressed
      sendEvent(evt.owner, [[EventSetBuildingTarget target = INVALID_ENTITY_ID]])
    buildPreviewWasStarted = build_fortification_immediately(evt.owner, isShootPressed)
    builder_dot_shootPressed = buildPreviewWasStarted && isShootPressed
