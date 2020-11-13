require ecs
require math
require math.base
require game.es.lut_switcher_common

[es (track=(isAlive, input_dot_enabled), on_event=EventComponentsAppear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_death(evt : Event; isAlive : bool; input_dot_enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_death : Object)
    switch_color_grading(ecs_hash("death"), color_grading_items, color_grading_dot_death, !isAlive && input_dot_enabled)

[es (track=(isDowned, input_dot_enabled), on_event=EventComponentsAppear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_downed(evt : Event; isDowned : bool; input_dot_enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_downed : Object)
    switch_color_grading(ecs_hash("downed"), color_grading_items, color_grading_dot_downed, isDowned && input_dot_enabled)

[es (track=(isBlinded, input_dot_enabled), on_event=EventComponentsAppear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_no_vision(evt : Event; isBlinded : bool; input_dot_enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_is_no_vision : Object)
    switch_color_grading(ecs_hash("no_vision"), color_grading_items, color_grading_dot_is_no_vision, isBlinded && input_dot_enabled)

[es (track=(burning_dot_isBurning, input_dot_enabled), on_event=EventComponentsAppear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_burning(evt : Event; burning_dot_isBurning : bool; input_dot_enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_burning : Object)
    switch_color_grading(ecs_hash("burning"), color_grading_items, color_grading_dot_burning, burning_dot_isBurning && input_dot_enabled)

[es (track=(hasConcussedVision, input_dot_enabled), on_event=EventComponentsAppear, REQUIRE=(hero, watchedByPlr))]
def tonemapper_switcher_concussion(evt : Event; hasConcussedVision : bool; input_dot_enabled : bool)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_concussion : Object)
    switch_color_grading(ecs_hash("concussion"), color_grading_items, color_grading_dot_concussion, hasConcussedVision && input_dot_enabled)

[es (tag=gameClient, on_event=EventComponentsAppear, REQUIRE=watchedByPlr, REQUIRE_NOT=hero)]
def tonemapper_switcher_spectator(evt : Event)
  query() <| $ [es] (var color_grading_items : Array; color_grading_dot_alive : Object)
    add_grading(ecs_hash("alive"), color_grading_items, color_grading_dot_alive)

[es (tag=gameClient, on_event="events::EventLutSwitcherAliveState", on_event=(EventEntityCreated, EventComponentsAppear))]
def tonemapper_switcher_alive_es(
  evt : Event;
  var color_grading_items : ecs::Array;
  color_grading_dot_alive : Object)
  clear(color_grading_items)
  add_grading(ecs_hash("alive"), color_grading_items, color_grading_dot_alive)

[es (track=input_dot_enabled, on_event=EventComponentsAppear, REQUIRE=hero)]
def tonemapper_switcher_input(evt : Event; input_dot_enabled : bool)
  if !input_dot_enabled
    query() <| $ [es] (var color_grading_items : Array; color_grading_dot_alive : Object)
      clear(color_grading_items)
      add_grading(ecs_hash("alive"), color_grading_items, color_grading_dot_alive)

[es(before=post_fx_es)]
def combined_color_grading_init_es(
    info : ecs::UpdateStageInfoAct;
    tonemap_save : Object;
    var color_grading_items : Array;
    var color_grading : Object)
  set_color_grading(color_grading, tonemap_save)

  var idx = length(color_grading_items)
  while --idx >= 0
    var itemObj = getRW_ecs_object(color_grading_items[idx])
    var lifeTime = get_float(*itemObj, "life_time") ?? 0.
    var timings = get_Point3(*itemObj, "timings") ?? float3(0, 10000, 0)

    lifeTime += info.dt;
    if lifeTime > timings.x + timings.y + timings.z
      erase(color_grading_items, idx)
      continue

    set(*itemObj, "life_time", lifeTime)

  for grading_item in color_grading_items
    var itemObj = getRW_ecs_object(grading_item)
    var lifeTime = get_float(*itemObj, "life_time") ?? 0.
    var timings = get_Point3(*itemObj, "timings") ?? float3(0, 10000, 0)

    var state = 0.0
    if lifeTime < timings.x
      state = safediv(lifeTime, timings.x)
    elif lifeTime < timings.x + timings.y
      state = 1.0
    else
      state = saturate(1.0 - safediv((lifeTime - timings.x - timings.y), timings.z))

    // Apply easing function here
    state = state * state * (3.0 - 2.0 * state)

    for field in *itemObj
      if has(color_grading, field.key)
        let baseValue = deref(get_Point4(color_grading, field.key))
        let newValue = deref(get_Point4(field.value))
        set(color_grading, field.key, lerp(baseValue, newValue, float4(state)))
