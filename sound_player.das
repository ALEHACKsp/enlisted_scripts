options remove_unused_symbols = false
module sound_player
require ecs
require ecs.common
require soundHash
require soundSystem
require soundEvent
require DagorSystem
module sound_player;


[private]
def get_handle(snd : int3 const&) : int
  return snd.x

[private]
def get_id(snd : int3 const&) : uint
  return uint(snd.y)

[private]
def is_removable(snd : int3 const&) : bool
  return snd.z != 0

[private]
def need_remove_sound(snd : int3 const&) : bool
  return !soundEvent::is_valid_event_instance(get_handle(snd)) || (is_removable(snd) && !soundEvent::is_playing(get_handle(snd)))

[private]
def test_id(snd : int3 const&; id : uint)
  return id == get_id(snd) && id != sound_hash("")

def get_sound(group : IPoint3List; id : uint) : int
  var idx:int = length(group)
  while --idx >= 0
    let snd = group[idx]
    if test_id(snd, id)
      return get_handle(snd)
  return 0

[generic]
def has_sound(group : IPoint3List; id : uint) : bool
  return get_sound(group, id) != 0

def abandon_sound(var group : IPoint3List; id : uint)
  var idx:int = length(group)
  while --idx >= 0
    let snd = group[idx]
    if test_id(snd, id) || need_remove_sound(snd)
      var handle : int = get_handle(snd)
      soundEvent::abandon(handle)
      erase(group, idx)

def release_sound(var group : IPoint3List; id : uint)
  var idx:int = length(group)
  while --idx >= 0
    let snd = group[idx]
    if test_id(snd, id) || need_remove_sound(snd)
      var handle : int = get_handle(snd)
      soundEvent::release(handle)
      erase(group, idx)

def abandon_all_sounds(var group : IPoint3List)
  for snd in group
    var handle : int = get_handle(snd)
    soundEvent::abandon(handle)
  clear(group)

def release_all_sounds(var group : IPoint3List)
  for snd in group
    var handle : int = get_handle(snd)
    soundEvent::release(handle)
  clear(group)

def add_sound(var group : IPoint3List; id : uint; handle : int; removable : bool)
  abandon_sound(group, id)
  if handle != 0
    var snd : int3
    snd.x = handle
    snd.y = int(id)
    snd.z = removable ? 1 : 0
    push_back(group, snd)
    if length(group) >= 99
      logerr("Sound group seems too large({int(length(group))})");

[generic]
def get_tag(tags : ecs::Object; tag_str : string) : int64
  return tag_str != "" ? (get_int64_t(tags, tag_str) ?? 0l) : 0l // unhandled exception in dag_hash.h: dereferencing null ptr(""==null)

[generic]
def get_desc(descs : ecs::Object; desc_str : string) : ecs::Object const?
  return desc_str != "" ? get_ecs_object(descs, desc_str) : null


[private]
def get_option_tags(opt : ecs::Object; field : string)
  return get_int64_t(opt, field) ?? 0l


[private]
def get_option(path : ecs::Object const?; tags : int64)
  if path == null || !has(*path, "options")
    return path
  let opts = get_ecs_array(*((*path)["options"]))
  if opts == null
    return path
  for it in *opts
    let opt = get_ecs_object(it)
    if opt != null
      let onTags = get_option_tags(*opt, "_onTags")
      if onTags == (onTags & tags)
        if (get_option_tags(*opt, "_offTags") & tags) == 0l
          return opt
  return null

[generic]
def get_path_string(obj : ecs::Object; name, defaultValue : string)
  let str = get_ecs_string(obj, name)
  return str != null ? string(*str) : defaultValue

[private]
def get_option_path(obj : ecs::Object const; is_watched : bool; var result : string &) : bool
  if is_watched && has(obj, "hero")
    result = get_path_string(obj, "hero", "error")
    return true
  elif !is_watched && has(obj, "enemy")
    result = get_path_string(obj, "enemy", "error")
    return true
  elif has(obj, "path")
    result = get_path_string(obj, "path", "error")
    return true
  return false

def make_path(desc : ecs::Object; paths : ecs::Object; tags : int64; is_watched : bool; var result : string &) : bool
  result = ""
  if !has(desc, "path")
    return true
  let pathStr = get_path_string(desc, "path", "")
  let path = get_ecs_object(paths, pathStr)
  if path == null
    soundSystem::debug("path '{pathStr}' does not exist")
    return false
  let opt = get_option(path, tags)
  if opt == null
    soundSystem::debug("no matching option for path '{pathStr}', current tags are {tags}")
    return false
  return get_option_path(*opt, is_watched, result)

[generic]
def is_empty(obj : ecs::Object)
  return !has(obj, "name") && !has(obj, "path")


[private]
def play_name_path_impl(name : string; path : string; id : uint; pos : float3; var group : IPoint3List; removable : bool)
  let handle = soundEvent::init(name, path)
  soundEvent::set_pos(handle, pos)
  add_sound(group, id, handle, removable)
  soundEvent::start(handle)
  return handle

[private]
def play_name_path_impl(name : string; path : string; pos : float3; is_abandon : bool)
  var handle = soundEvent::init(name, path)
  soundEvent::set_pos(handle, pos)
  soundEvent::start(handle)
  if is_abandon
    soundEvent::abandon(handle)
  return handle

def play_name_path(name : string;
                   path : string;
                   id : uint;
                   pos : float3;
                   var group : IPoint3List;
                   is_watched_sound : bool;
                   removable : bool = true;
                   dist_threshold : float = 40.0)
  abandon_sound(group, id)
  if name != "" || path != ""
    if is_watched_sound || soundEvent::should_play(pos, dist_threshold)
      return play_name_path_impl(name, path, id, pos, group, removable)
  return 0

def play_name_path(name : string;
                   path : string;
                   pos : float3;
                   is_watched_sound : bool;
                   is_abandon : bool = true;
                   dist_threshold : float = 40.0)
  if name != "" || path != ""
    if is_watched_sound || soundEvent::should_play(pos, dist_threshold)
      return play_name_path_impl(name, path, pos, is_abandon)
  return 0

def play_desc_path(desc : ecs::Object;
                   path : string;
                   id : uint;
                   pos : float3;
                   var group : IPoint3List;
                   is_watched_sound : bool;
                   removable : bool = true;
                   dist_threshold : float = 40.0)
  abandon_sound(group, id)
  if path != "" && !is_empty(desc)
    if is_watched_sound || soundEvent::should_play(pos, dist_threshold)
      let name = get_path_string(desc, "name", "")
      if name != ""
        return play_name_path_impl(name, path, id, pos, group, removable)
  return 0

def play_desc_path(desc : ecs::Object;
                   path : string;
                   pos : float3;
                   is_watched_sound : bool;
                   is_abandon : bool = true;
                   dist_threshold : float = 40.0)
  if path != "" && !is_empty(desc)
    if is_watched_sound || soundEvent::should_play(pos, dist_threshold)
      let name = get_path_string(desc, "name", "")
      if name != ""
        return play_name_path_impl(name, path, pos, is_abandon)
  return 0

def play_desc(desc : ecs::Object;
              paths : ecs::Object;
              tags : int64;
              is_watched_sound : bool;
              pos : float3;
              id : uint;
              var group : IPoint3List;
              removable : bool = true;
              dist_threshold : float = 40.0)
  abandon_sound(group, id)
  if is_watched_sound || soundEvent::should_play(pos, dist_threshold)
    if !is_empty(desc)
      var path : string
      if make_path(desc, paths, tags, is_watched_sound, path)
        return play_desc_path(desc, path, id, pos, group, is_watched_sound, removable, dist_threshold)
  return 0

def play_desc(desc : ecs::Object;
              paths : ecs::Object;
              tags : int64;
              is_watched_sound : bool;
              pos : float3;
              is_abandon : bool = true;
              dist_threshold : float = 40.0;
              desc_name : string = "")
  if is_watched_sound || soundEvent::should_play(pos, dist_threshold)
    if !is_empty(desc)
      let name = get_path_string(desc, "name", desc_name)
      var path : string
      if make_path(desc, paths, tags, is_watched_sound, path)
        return play_name_path_impl(name, path, pos, is_abandon)
  return 0

def play_sound(desc_name : string;
               paths : ecs::Object;
               descs : ecs::Object;
               tags : int64;
               is_watched_sound : bool;
               pos : float3;
               is_abandon : bool = true;
               dist_threshold : float = 40.0)
  let desc = get_desc(descs, desc_name)
  if desc != null
    return play_desc(*desc, paths, tags, is_watched_sound, pos, is_abandon, dist_threshold, desc_name)
  soundSystem::debug("no desc '{desc_name}' exists")
  return 0

def play_sound(desc_name : string;
               id : uint;
               paths : ecs::Object;
               descs : ecs::Object;
               tags : int64;
               is_watched_sound : bool;
               pos : float3;
               var group : IPoint3List;
               removable : bool = true;
               dist_threshold : float = 40.0)
  abandon_sound(group, id)
  let desc = get_desc(descs, desc_name)
  if desc != null
    return play_desc(*desc, paths, tags, is_watched_sound, pos, id, group, removable, dist_threshold)
  soundSystem::debug("no desc '{desc_name}' exists")
  return 0
