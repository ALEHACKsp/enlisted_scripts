options remove_unused_symbols = false
module sound_desc
require ecs
require soundHash
module sound_desc;

def find_desc_id(obj_name:string; name:string; descs:ecs::Array)
  var idx:int=0
  for it in descs
    let obj = get_ecs_object(it)
    if obj != null
      let objName = get_ecs_string(obj, obj_name)
      if objName != null
        if name == string(deref(objName))
          return idx
    ++idx
  return -1

def find_desc_id(obj_name:string; name_hash:uint; descs:ecs::Array)
  var idx:int=0
  for it in descs
    let obj = get_ecs_object(it)
    if obj != null
      let objName = get_ecs_string(obj, obj_name)
      if objName != null
        if name_hash == sound_hash(string(*objName))
          return idx
    ++idx
  return -1

[generic]
def get_desc(idx:int; descs:ecs::Array)
  return idx >= 0 && idx < length(descs) ? get_ecs_object(descs[idx]) : null
