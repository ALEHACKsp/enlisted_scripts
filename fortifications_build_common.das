options remove_unused_symbols = false
module fortifications_build_common
require game.utils.team
require GridCollision
require EnlistedWeapon
require DagorSystem
require DagorMath
require RendInst
require CollRes
require Dacoll
require math.base
require ecs

def get_engineer_building_speed_mul(human_weap_dot_gunEids : ecs::EidList const)
  var buildingSpeedMul = 1.0
  for weapEid in human_weap_dot_gunEids
    if has(weapEid, "engineerBuildingSpeedMul")
      buildingSpeedMul = get_float(weapEid, "engineerBuildingSpeedMul") ?? 1.0
      break
  return buildingSpeedMul

def get_building_collres(base_collres, riextra_name)
  if base_collres != null
    return base_collres
  if riextra_name != null
    let resName = string(deref(riextra_name))
    let resIndex = get_rigen_extra_res_idx(resName)
    return get_rigen_extra_coll_res(resIndex)
  return null

def is_conflict_with_server_preview(tm, box; exclude_eid: EntityId = INVALID_ENTITY_ID; var base_collres: CollisionResource? = null)
  var objectFound = false
  find_query() <| $[es (REQUIRE=builder_server_preview)](eid: EntityId;
                                                         transform: float3x4;
                                                         buildingBoxMin : float3;
                                                         buildingBoxMax : float3;
                                                         previewCollres: CollisionResource?;
                                                         ri_preview_dot_name: das_string?)
    if eid == exclude_eid
      return false
    var serverPreviewCollres = get_building_collres(previewCollres, ri_preview_dot_name)
    objectFound = check_bbox3_intersection(box, tm, BBox3(buildingBoxMin, buildingBoxMax), transform)
    if objectFound && serverPreviewCollres != null && base_collres != null
      var intersectPoint : float3
      objectFound = test_collres_intersection(*base_collres, tm, *serverPreviewCollres, transform, intersectPoint, intersectPoint)
    return objectFound
  return objectFound

def is_conflict_with_other_buildings(tm, box; exclude_eid: EntityId = INVALID_ENTITY_ID; var base_collres: CollisionResource? = null)
  var objectFound = false
  find_query() <| $[es (REQUIRE=buildTypeId)](eid: EntityId;
                                              transform: float3x4;
                                              ri_extra_dot_bboxMin : float3;
                                              ri_extra_dot_bboxMax : float3;
                                              previewCollres: CollisionResource?;
                                              ri_extra_dot_name: das_string?)
    if eid == exclude_eid
      return false
    objectFound = check_bbox3_intersection(box, tm, BBox3(ri_extra_dot_bboxMin, ri_extra_dot_bboxMax), transform)
    var buildingCollres = get_building_collres(previewCollres, ri_extra_dot_name)
    if objectFound && buildingCollres != null && base_collres != null
      var intersectPoint : float3
      objectFound = test_collres_intersection(*base_collres, tm, *buildingCollres, transform, intersectPoint, intersectPoint)
    return objectFound
  return objectFound

def is_conflict_with_objects_in_grid(tm, box; exclude_eid: EntityId = INVALID_ENTITY_ID; var base_collres: CollisionResource? = null)
  var objectFound = false
  var buildingWorldBox = BBox3(tm[3], length(box.width))
  find_object_in_grid(GridType GT_DEFAULT, buildingWorldBox) <| $(it:TraceableGridCollision#)
    if it.eid == exclude_eid
      return false
    ecs::query(it.eid) <| $ [es] (collres: CollisionResource&;
                                  transform: float3x4;
                                  isAlive = false)
      if has(it.eid, "human") && !isAlive
        return
      let colBox = collres.vFullBBox
      let colBoxMin = colBox.bmin.xyz
      let colBoxMax = colBox.bmax.xyz
      var colBbox3 = BBox3(colBoxMin, colBoxMax)
      objectFound = check_bbox3_intersection(box, tm, colBbox3, transform)
      if objectFound && base_collres != null
        var intersectPoint : float3
        objectFound = test_collres_intersection(*base_collres, tm, collres, transform, intersectPoint, intersectPoint)
    return objectFound
  return objectFound

def is_conflict_with_world(tm; collobj: CollisionObject; collobj_offset : float; base_collres: CollisionResource? = null)
  if base_collres == null
    return false
  var tmCopy = tm
  tmCopy[3] = tmCopy[3] + normalize(tmCopy[1]) * collobj_offset
  return test_collision_world(collobj, tmCopy, (*base_collres).boundingSphere.r)

def is_conflict_objects_in_building_box(tm, box; collobj: CollisionObject; collobj_offset: float; exclude_eid: EntityId = INVALID_ENTITY_ID; var base_collres: CollisionResource? = null)
  var isConflict = (is_conflict_with_server_preview(tm, box, exclude_eid, base_collres) ||
                    is_conflict_with_other_buildings(tm, box, exclude_eid, base_collres) ||
                    is_conflict_with_objects_in_grid(tm, box, exclude_eid, base_collres) ||
                    is_conflict_with_world(tm, collobj, collobj_offset, base_collres))
  return isConflict

def find_respawn_eid_for_team_in_radius(pos; radius; exclude_eid = INVALID_ENTITY_ID; respawnTeam = TEAM_UNASSIGNED)
  if radius < 0.0
    return INVALID_ENTITY_ID

  var respawnEid = INVALID_ENTITY_ID
  find_query() <| $[es (REQUIRE=respawnObject)](eid: EntityId; transform: float3x4; team = TEAM_UNASSIGNED; previewTeam = TEAM_UNASSIGNED; active = true; semi_transparent_dot_visible = true)
    if team != respawnTeam  && previewTeam != respawnTeam
      return false
    let inRadius  = length_sq(transform[3] - pos) < square(radius)
    let isVisible = semi_transparent_dot_visible
    if active && inRadius && isVisible && eid != exclude_eid
      respawnEid = eid
    return !!respawnEid

  return respawnEid

def is_distance_to_capture_points_valid(pos; min_distance)
  if min_distance < 0.0
    return true
  return !find_query() <| $[es (REQUIRE=capzone)](transform: float3x4; active: bool; sphere_zone_dot_radius = 0.0)
    if !active
      return false
    let distanceSq = length_sq(transform[3] - pos)
    if sphere_zone_dot_radius > 0.0
      return distanceSq < square(min_distance + sphere_zone_dot_radius)
    let halfDiag = length(transform[0] + transform[2]) * 0.5
    return distanceSq < square(min_distance + halfDiag)

def respawns_distance_error_notify_player(operatorEid; respawnObject)
  let isPreview = has(respawnObject, "builder_preview")
  let errorMsg  = isPreview ? "building_blocked_too_close_to_other_respawn_preview" : "building_blocked_too_close_to_respawns"
  sendEvent(operatorEid, [[CmdHeroLogEvent event=errorMsg, text=errorMsg]])

def get_player_eid_interacting_building(building_eid, exclude_eid = INVALID_ENTITY_ID)
  var player_eid = INVALID_ENTITY_ID
  find_query() <| $[es](eid: EntityId; building_action_dot_target: EntityId)
    if eid == exclude_eid
      return false
    if building_action_dot_target == building_eid
      player_eid = eid
    return !!player_eid
  return player_eid

def is_not_attachable_gun(gun_eid: EntityId; transform : float3x4; check_points: Point3List)
  for pt in check_points
    var checkPt = transform * pt
    let dir = float3(0.0, -1.0, 0.0)
    var norm : float3
    var t = 10.0
    traceray_normalized(checkPt, dir, t, norm)
    checkPt += dir * t
    if gun_needs_detach(gun_eid, checkPt)
      return true
  return false

def is_not_attachable_gun(building_eid : EntityId)
  var res = false
  query(building_eid) <| $[es](transform: float3x4;
                               gun_attachable_check_dot_points: Point3List)
    res ||= is_not_attachable_gun(building_eid, transform, gun_attachable_check_dot_points)
  find_query() <| $[es](eid: EntityId;
                        transform: float3x4;
                        gun_attachable_check_dot_points: Point3List;
                        dependsOnPreviewEid : EntityId)
    if dependsOnPreviewEid == building_eid
      res ||= is_not_attachable_gun(eid, transform, gun_attachable_check_dot_points)
      return true
    return false
  return res
