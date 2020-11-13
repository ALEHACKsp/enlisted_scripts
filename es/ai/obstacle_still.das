require ecs
require game.es.events
require pathfinder
require strings
require DagorMath
require DagorSystem
require CollRes
require RendInst

let
  FORWARD = float3(1.0f, 0.0, 0.0f)

def still_obstacles_from_grid(cur_time : float; obstacle_template : string)
  ecs::query() <| $ [es (REQUIRE_NOT=obstacle_dot_still, REQUIRE_NOT=human, REQUIRE_NOT=obstacle_dot_handle,
    REQUIRE=collres, REQUIRE=gridcoll)] (eid : EntityId; transform : float3x4; gridcoll_dot_enabled : bool = true; gridcoll_dot_type : string = "")
    if gridcoll_dot_enabled && (empty(gridcoll_dot_type) || (gridcoll_dot_type == "default"))
      addSubTemplate(eid, obstacle_template) <| $ (var init: ComponentsInitializer)
        set(init, "obstacle.lastStillTransform", transform)
        set(init, "obstacle.lastStillTime", cur_time)
  ecs::query() <| $ [es (REQUIRE=obstacle_dot_still)] (eid : EntityId; gridcoll_dot_enabled : bool)
    if !gridcoll_dot_enabled
      removeSubTemplate(eid, obstacle_template)

def still_obstacles_from_riextra(cur_time : float; obstacle_template : string)
  ecs::query() <| $ [es (REQUIRE_NOT=obstacle_dot_still, REQUIRE_NOT=obstacle_dot_handle,
    REQUIRE_NOT=ri_extra_dot_handle)] (eid : EntityId; transform : float3x4; ri_extra : RiExtraComponent)
    let riType = handle_to_ri_type(ri_extra.handle)
    if get_ri_gen_extra_collres(int(riType)) != null
      addSubTemplate(eid, obstacle_template) <| $ (var init: ComponentsInitializer)
        set(init, "obstacle.lastStillTransform", transform)
        set(init, "obstacle.lastStillTime", cur_time)

def still_obstacles_update(cur_time : float)
  ecs::query() <| $ [es (REQUIRE=obstacle_dot_still)] (eid : EntityId;
                                                       obstacle_dot_checkDelta : float;
                                                       obstacle_dot_stillPosThreshold : float;
                                                       obstacle_dot_stillAngCosThreshold : float;
                                                       obstacle_dot_stillTimeout : float;
                                                       obstacle_dot_initialStillTimeout : float;
                                                       obstacle_dot_padding : float = 0.0f;
                                                       obstacle_dot_paddingSide : float = 0.0f;
                                                       var obstacle_dot_stillCount : int&;
                                                       var obstacle_dot_handle : int&;
                                                       var obstacle_dot_lastCheckTime : float&;
                                                       var obstacle_dot_lastStillTransform : float3x4&;
                                                       var obstacle_dot_lastStillTime : float&;
                                                       transform : float3x4;
                                                       collres : CollisionResource?;
                                                       ri_extra : RiExtraComponent?)
    if (cur_time < obstacle_dot_lastCheckTime + obstacle_dot_checkDelta)
      return
    obstacle_dot_lastCheckTime = cur_time
    if ((length_sq(transform[3] - obstacle_dot_lastStillTransform[3]) > obstacle_dot_stillPosThreshold * obstacle_dot_stillPosThreshold) ||
      (dot(rotate(transform, FORWARD), rotate(obstacle_dot_lastStillTransform, FORWARD)) < obstacle_dot_stillAngCosThreshold))
      obstacle_dot_lastStillTime = cur_time
      obstacle_dot_lastStillTransform = transform
      tilecache_obstacle_remove(obstacle_dot_handle)
      obstacle_dot_handle = 0
      return
    let timeout = (obstacle_dot_stillCount > 0) ? obstacle_dot_stillTimeout : obstacle_dot_initialStillTimeout
    if (cur_time < obstacle_dot_lastStillTime + timeout)
      return
    obstacle_dot_lastStillTime = cur_time
    obstacle_dot_lastStillTransform = transform
    if obstacle_dot_handle == 0
      ++obstacle_dot_stillCount
      var cr : CollisionResource? = null
      if collres != null
        cr = collres
      elif ri_extra != null
        let riType = handle_to_ri_type((*ri_extra).handle)
        cr = get_ri_gen_extra_collres(int(riType))
      if cr != null
        var box = BBox3((*cr).vFullBBox)
        bbox3_set_min(box, bbox3_min(box) - float3(0.0f, obstacle_dot_padding, 0.0f))
        bbox3_inflateXZ(box, obstacle_dot_paddingSide)
        obstacle_dot_handle = tilecache_obstacle_add(transform, box)
      else
        logerr("No collision resource in still_obstacles_update: {eid} {getEntityTemplateName(eid)}")

[es (tag=server, no_order)]
def still_obstacles_check_es(info : UpdateStageInfoAct;
                             var still_obstacles_dot_lastCheckTime : float&;
                             still_obstacles_dot_checkDelta : float;
                             still_obstacles_dot_obstacleTemplate : string)
  if !tilecache_is_loaded()
    return
  if (info.curTime < still_obstacles_dot_lastCheckTime + still_obstacles_dot_checkDelta)
    return
  still_obstacles_dot_lastCheckTime = info.curTime
  still_obstacles_from_grid(info.curTime, still_obstacles_dot_obstacleTemplate)
  still_obstacles_from_riextra(info.curTime, still_obstacles_dot_obstacleTemplate)
  still_obstacles_update(info.curTime)
