options remove_unused_symbols = false
module lut_switcher_common
require ecs

def add_grading(
  item_id : uint;
  var color_grading_items : ecs::Array;
  color_grading : Object)
  push_back(color_grading_items, color_grading)
  var itemObj = getRW_ecs_object(color_grading_items[length(color_grading_items) - 1])
  set(*itemObj, "unique_id", int(item_id))

def remove_grading(item_id : uint;
  var color_grading_items : ecs::Array)
  var idx = length(color_grading_items)
  while --idx >= 0
    var itemObj = getRW_ecs_object(color_grading_items[idx])
    if uint(get_int(*itemObj, "unique_id") ?? 0) == item_id
      var timings = get_Point3(*itemObj, "timings")
      if timings != null && *timings.z > 0f
        let lifeTime = get_float(*itemObj, "life_time") ?? 0f
        if lifeTime < *timings.x + *timings.y
          set(*itemObj, "life_time", *timings.x + *timings.y) // advance to end
      else
        erase(color_grading_items, idx)

def set_color_grading(var to; from)
  for field in from
    if has(to, field.key)
      deref(to[field.key]) := field.value

def switch_color_grading(item_id : uint;
                         var color_grading_items : Array;
                         color_grading : Object;
                         is_enabled : bool)
  if is_enabled
    add_grading(item_id, color_grading_items, color_grading)
  else
    remove_grading(item_id, color_grading_items)

def has_color_grading(color_grading_items : Array; item_id : uint)
  for it in color_grading_items
    if uint(get_int(get_ecs_object(it), "unique_id") ?? 0) == item_id
      return true
  return false
