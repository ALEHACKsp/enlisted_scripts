require ecs
require DagorConsole
require DagorDebug3D

[console_cmd(name="capzone.show_nearest_navmesh_pos")]
def showNearestNavPosition()
  query() <| $[es](capzone_dot_hasNearestNavmeshPos : bool; capzone_dot_nearestNavmeshPos : float3)
    if capzone_dot_hasNearestNavmeshPos
      draw_debug_sphere_buffered(capzone_dot_nearestNavmeshPos, 0.4f, E3DCOLOR(0xFF00FF00), 24, 1000)
