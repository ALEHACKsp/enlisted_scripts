require pathfinder

[generic]
def find_path(start_pos, end_pos : float3; dist_to_path, step_size, slop:float; subexpr:block<(data:array<float3>):void>) : bool
  return _builtin_find_path(start_pos, end_pos, dist_to_path, step_size, slop, subexpr)

[generic]
def find_path(start_pos, end_pos : float3; dist_to_path, step_size, slop:float) : bool
  return _builtin_find_path(start_pos, end_pos, dist_to_path, step_size, slop) <| $[unused_argument(_)](_:array<float3>) {}

[generic]
def find_path(start_pos, end_pos : float3; dist_to_path, step_size:float; subexpr:block<(data:array<float3>):void>) : bool
  return _builtin_find_path(start_pos, end_pos, dist_to_path, step_size, 2.5, subexpr)

[generic]
def find_path(start_pos, end_pos : float3; dist_to_path:float; subexpr:block<(data:array<float3>):void>) : bool
  return _builtin_find_path(start_pos, end_pos, dist_to_path, 10.0, 2.5, subexpr)

[generic]
def find_path(start_pos, end_pos : float3; subexpr:block<(data:array<float3>):void>) : bool
  return _builtin_find_path(start_pos, end_pos, 10.0, 10.0, 2.5, subexpr)
