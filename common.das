options remove_unused_symbols = false
module common
require ecs
require DagorMathUtils
require strings

[generic]
def get_string(obj; name, orDefault : string)
  let str = get_ecs_string(obj, name)
  return str != null ? string(deref(str)) : orDefault

[generic]
def get_string(obj; orDefault : string)
  let str = get_ecs_string(obj)
  return str != null ? string(deref(str)) : orDefault

[generic]
def find_index_if(arr : ecs::Array; condition : block<(elem:ChildComponent):bool>) : int
  for i in iter_range(arr)
    if invoke(condition, arr[i])
      return i
  return -1

[generic]
def find_index(arr : ecs::Array; eid : EntityId) : int
  return find_index_if(arr) <| $ (elem) : bool
    let tryEid = get_Eid(elem)
    assert(tryEid != null, "ecs::Array child type != ecs::EntityId")
    return tryEid != null && *tryEid == eid

[generic]
def has_value(arr : ecs::Array; eid : EntityId) : bool
  return find_index(arr, eid) >= 0

[generic]
def find_index(arr, val) : int
  for i in iter_range(arr)
    if arr[i] == val
      return i
  return -1

def get(val, idx)
  return val[idx]

def get_safe(val, idx, default_value)
  return length(val) > idx ? val[idx] : default_value

def get_or(val, idx, default_block)
  return length(val) > idx ? val[idx] : invoke(default_block)

[generic]
def is_point_in_poly(pt : float2; points : ecs::Point2List)
  unsafe
    return is_point_in_poly(pt, data_ptr(points), length(points))

// Returns random float in range [0..1) based on eid value
[generic]
def eid_unit(eid : EntityId)
  let eidHash = 84696351u ^ uint(eid) // fnv1-like hash
  return float(eidHash & 16777215u) / 16777216.f // float values are int uniform only within low 24 bits

[generic]
def join_keys(obj : Object; sep = ", ")
  return build_string() <| $(var str)
    var first = true
    for it in obj
      if !first
        str |> write(sep)
      else
        first = false
      str |> write(it.key)
