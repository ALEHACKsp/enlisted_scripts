require ecs
require HumanPhys
require DagorSystem
require DagorMath
require PhysVars
require EnlistedHuman
require EnlistedPhys
require math
require math.easing


[es(after=human_optics_camera_es, tag=gameClient)]
def camera_magnification_es(
  info : UpdateStageInfoAct;
  human_net_phys : HumanActor;
  var camera_dot_magnification : float&;
  human_dot_cameraMagnificationOnHoldBreath : float;
  camera_dot_breathMagnificationSpeed : float;
  var camera_dot_breathMagnificationProgress : float&;
  isAlive : bool)

  if isAlive && (human_net_phys.phys.currentState.aimPosition > 0.f)
    let dir = is_hold_breath(human_net_phys.phys.currentState) ? 1.0 : -1.0
    camera_dot_breathMagnificationProgress = clamp(camera_dot_breathMagnificationProgress + info.dt * camera_dot_breathMagnificationSpeed * dir, 0.f, 1.f)
    camera_dot_magnification *= lerp(1.0, human_dot_cameraMagnificationOnHoldBreath, inOutQuad(camera_dot_breathMagnificationProgress))
