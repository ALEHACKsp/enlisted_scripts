require ecs
require app
require math
require GamePhys
require EnlistedPhysObj
require game.es.events

[es (tag=server, REQUIRE=shell, REQUIRE=shell_dot_orientationByVelocity)]
def shell_orientation_by_velocity(evt: CmdPostPhysUpdate; var phys_obj_net_phys: PhysObjActor)
  var orient & = phys_obj_net_phys.phys.currentState.location.O
  let vel & = phys_obj_net_phys.phys.currentState.velocity
  let dir = float3(vel.x, -vel.y, -vel.z)
  set_yp0(orient, dir)