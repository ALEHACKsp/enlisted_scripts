require ecs
require math
require math.base
require DagorMath
require EnlistedPhysObj
require game.es.events
require DaWeaponProps

def explode_shell(eid : EntityId;
                  curTime : float;
                  phys_obj_net_phys : PhysObjActor;
                  var shell_dot_active : bool&;
                  var shell_dot_launchTime : float&;
                  shell_dot_fuseTime : float;
                  shell_dot_cleanupTime : float)
  shell_dot_active = false
  if curTime >= shell_dot_launchTime + shell_dot_fuseTime
    let prevPos = float3(phys_obj_net_phys.phys.previousState.location.P)
    let vel = phys_obj_net_phys.phys.currentState.velocity
    sendEvent(eid, [[CmdShellExplode position=phys_obj_net_phys.phys.currentState.contactPoint, prevPos=prevPos, vel=vel]])
  else
    sendEvent(eid, [[CmdBodyCleanup time=shell_dot_cleanupTime]])

[es (REQUIRE=shell_dot_explodeOnContact)]
def explode_on_contact_shell_contact(evt : CmdPostPhysUpdate;
                                     eid : EntityId;
                                     phys_obj_net_phys : PhysObjActor;
                                     var shell_dot_active : bool&;
                                     var shell_dot_launchTime : float&;
                                     shell_dot_fuseTime : float = 0.0;
                                     shell_dot_cleanupTime : float = 5.0)
  if !shell_dot_active
    return
  let curTime = float(evt.tick) * evt.dt
  if shell_dot_launchTime < 0.0
    shell_dot_launchTime = curTime
  if !phys_obj_net_phys.phys.currentState.hadContact
    return
  explode_shell(eid, curTime, phys_obj_net_phys, shell_dot_active, shell_dot_launchTime, shell_dot_fuseTime, shell_dot_cleanupTime)


[es (REQUIRE=shell_dot_explodeOnSpeedDrop)]
def explode_on_speed_drop_shell_contact(evt : CmdPostPhysUpdate;
                                        eid : EntityId;
                                        phys_obj_net_phys : PhysObjActor;
                                        shell_dot_shell_id_dot_shell_id : int;
                                        shell_dot_activationSpeedDropThreshold : float;
                                        var shell_dot_active : bool&;
                                        var shell_dot_launchTime : float&;
                                        shell_dot_fuseTime : float = 0.0;
                                        shell_dot_cleanupTime : float = 5.0)
  if !shell_dot_active
    return

  let curTime = float(evt.tick) * evt.dt
  if shell_dot_launchTime < 0.f
    shell_dot_launchTime = curTime;
  if !phys_obj_net_phys.phys.currentState.hadContact
    return
  if phys_obj_net_phys.phys.hasRiDestroyingCollision
    return

  let vel = phys_obj_net_phys.phys.currentState.velocity
  let startProps = get_shell_start_props(shell_dot_shell_id_dot_shell_id);
  if startProps != null && safediv(length(vel), *startProps.speed) >= shell_dot_activationSpeedDropThreshold
    return

  explode_shell(eid, curTime, phys_obj_net_phys, shell_dot_active, shell_dot_launchTime, shell_dot_fuseTime, shell_dot_cleanupTime)
