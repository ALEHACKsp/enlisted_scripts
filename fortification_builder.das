require enlisted.game.es.fortifications_build_common
require enlisted.game.es.enlisted_events
require game.es.events
require game.utils.team
require DagorMath
require math.base
require CollRes
require Dacoll
require ecs

[es (on_event=EventEntityDestroyed, tag=server, REQUIRE=buildingRadius)]
def building_target_destroyed(evt: Event; eid: EntityId)
  let operatorEid = get_player_eid_interacting_building(eid)
  sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])

[es (tag=server, no_order)]
def building_fortification_building_object(info: UpdateStageInfoAct;
                                           eid: EntityId;
                                           building_action_dot_target: EntityId;
                                           transform: float3x4;
                                           team: int;
                                           human_use_object_dot_useDist: float;
                                           human_weap_dot_gunEids: ecs::EidList;
                                           var building_action_dot_lastActionAtTime: float&;
                                           building_action_dot_updateInterval: float)
  if !building_action_dot_target || building_action_dot_lastActionAtTime + building_action_dot_updateInterval > info.curTime
    return
  if building_action_dot_lastActionAtTime == -1.0
    building_action_dot_lastActionAtTime = info.curTime
    return
  let operatorEid = eid
  let operatorPos = transform[3]
  query(building_action_dot_target) <| $[es](eid: EntityId;
                                             transform: float3x4;
                                             var building_builder_dot_timeToBuild: float&;
                                             building_builder_dot_maxTimeToBuild: float;
                                             buildingBoxMin: float3;
                                             buildingBoxMax: float3;
                                             instantiateTemplate: string;
                                             additionalBuildingTemplate: string;
                                             buildingRadius: float;
                                             buildingSoundTag: string;
                                             buildByPlayer: EntityId;
                                             buildTypeId: int;
                                             previewTeam: int;
                                             savePreviewTeam = false;
                                             building_builder_dot_minDistanceToRespawns = -1.0;
                                             building_builder_dot_minDistanceToCapturePoints = -1.0;
                                             ri_preview_dot_name: das_string?;
                                             previewCollres: CollisionResource?;
                                             previewCollobj: CollisionObject;
                                             previewCollobjOffset: float;
                                             destroyInactiveTimeOut: float?;
                                             var destroyByInactiveShredderAtTime: float?)
    let buildingPos = transform[3]
    if length_sq(buildingPos-operatorPos) > square(human_use_object_dot_useDist)
      sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return
    if team != previewTeam
      sendEvent(operatorEid, [[CmdHeroLogEvent event="building_cannot_confirm_by_enemy", text="building_cannot_confirm_by_enemy"]])
      sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      return
    let buildingSpeedMul = get_engineer_building_speed_mul(human_weap_dot_gunEids)
    building_builder_dot_timeToBuild += (info.curTime - building_action_dot_lastActionAtTime) * buildingSpeedMul
    building_action_dot_lastActionAtTime = info.curTime
    if destroyByInactiveShredderAtTime != null && destroyInactiveTimeOut != null
      *destroyByInactiveShredderAtTime = building_action_dot_lastActionAtTime + *destroyInactiveTimeOut
    if building_builder_dot_timeToBuild > building_builder_dot_maxTimeToBuild
      let respawnObject = find_respawn_eid_for_team_in_radius(buildingPos, building_builder_dot_minDistanceToRespawns, eid, previewTeam)
      if !!respawnObject
        respawns_distance_error_notify_player(operatorEid, respawnObject)
        sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      if !is_distance_to_capture_points_valid(buildingPos, building_builder_dot_minDistanceToCapturePoints)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_blocked_too_close_to_capture_points", text="building_blocked_too_close_to_capture_points"]])
        sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      var baseCollres = get_building_collres(previewCollres, ri_preview_dot_name)
      if is_conflict_objects_in_building_box(transform, BBox3(buildingBoxMin, buildingBoxMax), previewCollobj, previewCollobjOffset, eid, baseCollres)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_cannot_confirm_when_objects_in", text="building_cannot_confirm_when_objects_in"]])
        sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      if is_not_attachable_gun(eid)
        sendEvent(operatorEid, [[CmdHeroLogEvent event="building_gun_not_attachable", text="building_gun_not_attachable"]])
        sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
        return
      createEntity("{additionalBuildingTemplate}+{instantiateTemplate}") <| $ (var init: ComponentsInitializer)
        set(init, "transform", transform)
        set(init, "buildTypeId", buildTypeId)
        set(init, "buildByPlayer", buildByPlayer)
        set(init, "buildingRadius", buildingRadius)
        set(init, "buildingSoundTag", buildingSoundTag)
        set(init, "disableCapturePointsRadius", building_builder_dot_minDistanceToCapturePoints)
        set(init, "disableRespawnPointsRadius", building_builder_dot_minDistanceToRespawns)
        if savePreviewTeam
          set(init, "team", previewTeam)
      sendEvent(operatorEid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])
      destroyEntity(eid)

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=gameClient, REQUIRE=buildByPlayer)]
def builded_turret_visual_shoot_tm_es(evt: Event; transform: float3x4; var turret_current_visual_shoot_tm: float3x4)
  turret_current_visual_shoot_tm = transform