require ecs
require Dacoll
require math

typedef
  riex_handle_t = uint

[generic]
def get_min_max_hmap_list_in_circle(center: float2; rad: float; subexpr: block<(var data:array<float2>):void>)
  _builtin_get_min_max_hmap_list_in_circle(center, rad, subexpr)

[generic]
def traceray_normalized(pos, dir : float3; var t : float&; var out_norm : float3&) : bool
  return Dacoll::traceray_normalized(pos, dir, t, out_norm, Dacoll::ETF_DEFAULT)

[generic]
def traceht_water_at_time(pos: float3; t: float; time: float; var underwater : bool&) : float
  var displacement: float3
  return Dacoll::traceht_water_at_time(pos, t, time, underwater, displacement)

[generic]
def sphere_cast(from, to : float3; rad : float; var out : ShapeQueryOutput; cast_mat_id : int = -1)
  return _builtin_sphere_cast(from, to, rad, out, cast_mat_id)
