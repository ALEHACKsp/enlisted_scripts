require ecs
require math
require math.base
require DagorSystem

def approach_move(from, to: float3; dt: float; tau: float; min_vel: float) : float3
  if length(to - from) < min_vel * dt
    return to
  let newVal = approach(from, to, dt, tau)
  if length(newVal - from) < min_vel * dt
    return move_to(from, to, dt, min_vel)
  return approach(from, to, dt, tau)

[es(before=shooter_cam_es)]
def shooter_camera_offset_modifier_es(info: UpdateStageInfoAct; var shooter_cam_dot_additionalOffset: float3&;
                                      shooter_cam_dot_wishAdditionalOffset : float3; shooter_cam_dot_additionalOffsetTau : float)
  shooter_cam_dot_additionalOffset = approach_move(shooter_cam_dot_additionalOffset, shooter_cam_dot_wishAdditionalOffset, info.dt, shooter_cam_dot_additionalOffsetTau, 1.0)

[es(before=shooter_cam_es)]
def shooter_camera_magnification_modifier_es(info: UpdateStageInfoAct; var shooter_cam_dot_magnificationMult: float&;
                                             shooter_cam_dot_wishMagnificationMult : float; shooter_cam_dot_magnificationTau : float)
  shooter_cam_dot_magnificationMult = approach(shooter_cam_dot_magnificationMult, shooter_cam_dot_wishMagnificationMult, info.dt, shooter_cam_dot_magnificationTau)

