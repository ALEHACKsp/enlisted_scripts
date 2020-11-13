options remove_unused_symbols = false
module walker_common
require HumanPhys
require DagorDataBlock
require DagorRandom
require math
require math.base
require pathfinder

let
  STANCE_STAND = 2
  STANCE_CROUCH = 1
  STANCE_CRAWL = 0

[generic]
def determinate_stance(phys_state : HumanPhysState)
  if phys_state.isCrawl
    return STANCE_CRAWL
  if phys_state.isCrouch
    return STANCE_CROUCH
  return STANCE_STAND

[generic]
def get_or(var blk : DataBlock; name : string; or_block)
  let res = blk |> datablock_find_param(name)
  return res >= 0 ? res : invoke(or_block)

[generic]
def get_or_create(var blk : DataBlock; name : string; default_value : float3) : int
  return get_or(blk, name) <| $() => blk |> datablock_setPoint3(name, default_value)

[generic]
def get_or_create(var blk : DataBlock; name : string; default_value : int) : int
  return get_or(blk, name) <| $() => blk |> datablock_setInt(name, default_value)

[generic]
def get_or_create(var blk : DataBlock; name : string; default_value : float) : int
  return get_or(blk, name) <| $() => blk |> datablock_setReal(name, default_value)

[generic]
def get_or_create(var blk : DataBlock; name : string; default_value : string) : int
  return get_or(blk, name) <| $() => blk |> datablock_setStr(name, default_value)

def find_nav_point_around(start_pos, center : float3; radius : float; tries : int; is_valid : block<(pos:float3):bool>) : tuple<pos : float3; valid : bool>
  let angleDelta = 2f * PI * safeinv(float(tries))
  let startAngle = angleDelta * gfrnd()
  for i in range(0, tries)
    let angle = startAngle + float(i) * angleDelta
    var s, c : float
    sincos(angle, s, c)
    var pos = center + float3(c * radius, 0f, s * radius)
    if !project_to_nearest_navmesh_point(pos, 1.)
      continue
    if !check_path(start_pos, pos, 0.5f, 0.5f, 0.5f)
      continue
    if invoke(is_valid, pos)
      return [[auto pos, true]]
  return [[auto float3(), false]]
