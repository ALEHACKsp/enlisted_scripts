require ecs
require app
require math.base
require Dacoll
require GridCollision
require DagorMath

[es (tag=render, REQUIRE=human_visibility_tracer)]
def human_visibility_tracer_es(info: UpdateStageInfoBeforeRender;
                               transform: float3x4;
                               visibilityTraceRadius: float = 10.f;
                               human_dot_canSeeLootItems: bool = true)
  let traceFromPos = transform[3] + float3(0.f, 1.f, 0.f)
  let heroPos = transform[3]
  let curTime = get_sync_time()

  if human_dot_canSeeLootItems
    for_each_object_in_grid(GridType GT_LOOT, BBox3(heroPos, visibilityTraceRadius)) <| $(ent: TraceableGridCollision#)
      if length_sq(ent.pos - heroPos) <= square(visibilityTraceRadius)
        if !has(ent.eid, "traceVisibility")
          addSubTemplate(ent.eid, "visibility_traceable_item")

  query() <| $[es (REQUIRE=traceVisibility)](eid: EntityId;
                                             transform: float3x4;
                                             timeBetweenVisibilityChecks: float;
                                             var lastVisibilityTraceTime: float&;
                                             var lastVisibilityTraceOffset: int&;
                                             var visible: bool&)
    if timeBetweenVisibilityChecks + lastVisibilityTraceTime > curTime
      return

    if length_sq(heroPos - transform[3]) > square(visibilityTraceRadius) || !human_dot_canSeeLootItems
      visible = false
      removeSubTemplate(eid, "visibility_traceable_item")
      return

    var traceable = false
    let maxTraces = 10
    let traceOffsMult = 0.1f
    let offs = lastVisibilityTraceOffset
    for j in range(maxTraces)
      let curOffs = (j + offs) % maxTraces
      let ht = float(curOffs) * traceOffsMult
      var dir = transform[3] + float3(0.f, ht, 0.f) - traceFromPos
      let dist = length(dir)
      dir *= safeinv(dist)
      traceable ||= !rayhit_normalized(traceFromPos, dir, dist, ETF_DEFAULT, -1)
      if traceable
        lastVisibilityTraceOffset = curOffs
        break

    visible = traceable
    lastVisibilityTraceTime = curTime