require ecs
require math
require math.base
require game.utils.hero
require game.es.events
require Gun
require Dacoll
require AnimV20
require GridCollision
require DagorDebug3D
require DagorMath
require DagorConsole

def draw_debug_flame(gloc : GunLocation; start_offset, distance, radius, cloud_offset, cloud_radius : float)
  if gloc.gunPos == null
    return
  let gunPos : float3& = *(gloc.gunPos)
  let gunDir = gloc.gunDir
  let end = gunPos + gunDir*distance
  let start = gunPos + gunDir * start_offset
  let humanRadius = 0.4

  var out : ShapeQueryOutput
  sphere_cast(start, end, radius, out)
  let hitPos = out.res
  let reachDist = distance * out.t
  var reachPos = start + gunDir * reachDist

  if out.t < 1.0
    draw_debug_line_buffered(start, hitPos, E3DCOLOR(0xFFFF0000), 1)
  draw_debug_line_buffered(start, reachPos, E3DCOLOR(0xFF00FF00), 1)
  draw_debug_capsule_buffered(start, reachPos, radius, E3DCOLOR(0xFFFF0000), 8, 1)

  let fireCloudStart = start + gunDir * cloud_offset
  let fireCloudEnd = start + gunDir * max(cloud_offset, distance - cloud_radius)
  draw_debug_capsule_buffered(fireCloudStart, fireCloudEnd, cloud_radius, E3DCOLOR(0xFF00FF00), 8, 1)
  draw_debug_capsule_buffered(fireCloudStart, fireCloudEnd, cloud_radius-humanRadius, E3DCOLOR(0xFF000000), 8, 1)

  for_each_object_in_grid(GridType GT_DEFAULT, BBox3(min(start, end), max(start, end))) <| $ (obj : TraceableGridCollision#)
    query(obj.eid) <| $ [es (REQUIRE=human)] (animchar : AnimcharBaseComponent;
                                              transform : float3x4;
                                              human_use_object_dot_nodeId : int)
      let headPos = animchar_get_node_wpos(animchar, human_use_object_dot_nodeId)
      let lowestPos = transform[3]
      draw_debug_capsule_buffered(lowestPos, headPos, humanRadius, E3DCOLOR(0xFFFFFFFF), 8, 1)

[es (tag=(gameClient,dev))]
def flamethrower_debug_phys(evt : CmdWeapPhysUpdate;
                             gun_dot_ammo : int;
                             flamethrower_dot_flameCurrentLength : float;
                             flamethrower_dot_debug: bool;
                             flamethrower_dot_flameStartOffset : float;
                             flamethrower_dot_cloudStartOffset : float;
                             flamethrower_dot_flameStreamRadius : float;
                             flamethrower_dot_flameCloudRadius : float)
  if !flamethrower_dot_debug || !evt.isForReal
    return

  var gctrl = evt.gctrl
  let gloc& = evt.gloc

  if gun_dot_ammo != 0 && gctrl.shoot
    draw_debug_flame(gloc, flamethrower_dot_flameStartOffset, flamethrower_dot_flameCurrentLength,
                     flamethrower_dot_flameStreamRadius, flamethrower_dot_cloudStartOffset, flamethrower_dot_flameCloudRadius)


[console_cmd(name="flameThrower.debug")]
def switch_flamethrower_debug()
  let hero = get_controlled_hero()
  find_query() <| $[es] (gun_dot_owner : EntityId; var flamethrower_dot_debug : bool&)
    if gun_dot_owner == hero
      flamethrower_dot_debug = !flamethrower_dot_debug
      return true
    return false
  find_query() <| $[es (REQUIRE=flamethrower_dot_fireTemplate, REQUIRE_NOT=flamethrower_dot_debug)] (eid : EntityId; gun_dot_owner : EntityId)
    if gun_dot_owner == hero
      addSubTemplate(eid, "flamethrower_debug")
      return true
    return false
