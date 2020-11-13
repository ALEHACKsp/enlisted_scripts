require ecs
require DagorConsole
require EnlistedActor
require EnlistedCamera
require DagorSystem
require game.es.server_debug
require game.utils.hero
require math

def teleport_eid_to(eid : EntityId; pos : float3; use_camera_pos : bool = false)
  var targetTm: float3x4
  let heroTm = get_TMatrix(eid, "transform")
  let cameraTm = get_TMatrix(get_cur_cam_entity(), "transform")
  if cameraTm != null
    identity(targetTm)
    targetTm[0] = normalize(cross(float3(0.f, -1.f, 0.f), (*cameraTm)[0]))
    targetTm[2] = normalize(cross((*cameraTm)[2], float3(0.f, 1.f, 0.f)))
    targetTm[3] = use_camera_pos ? (*cameraTm)[3] : pos
  elif heroTm != null
    targetTm = *heroTm
    if !use_camera_pos
      targetTm[3] = pos
  else
    logerr("Failed to get any transform")
    return
  teleport_phys_actor(eid, targetTm)

[console_cmd(name="phys.teleport", hint="[x,y,z] [hero eid] Uses camera if no coords are provided")]
def console_phys_teleport(x, y, z, w : float = 0.0)
  if y == 0.0 && z == 0.0 && w == 0.0
    let eid = x == 0.0 ? get_controlled_hero() : EntityId(uint(x))
    teleport_eid_to(eid, float3(0,0,0), true)
  else
    let eid = w == 0.0 ? get_controlled_hero() : EntityId(uint(w))
    teleport_eid_to(eid, float3(x,y,z), false)
