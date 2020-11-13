options remove_unused_symbols = false
module ang
require math
require math.base
require DagorMath
require DagorMathUtils

[generic]
def angles_to_dir(ang : float2) : float3
  var xSine, xCos, ySine, yCos : float
  sincos(-ang.x, xSine, xCos)
  sincos(ang.y, ySine, yCos)
  return float3(xCos * yCos, ySine, xSine * yCos)

[generic]
def safe_acos(x : float)
  return acos(clamp(x, -1.0, 1.0))

[generic]
def clamp_s_ang(angle: float;
                min_angle: float;
                max_angle: float) : float
  let normMin = norm_s_ang(min_angle - angle)
  let normMax = norm_s_ang(max_angle - angle)
  return (normMin <= 0.f && normMax >= 0.f) ? angle : (abs(normMax) - abs(normMin) >= 0.f ?  min_angle: max_angle)

[generic]
def clamp_angles_by_dir(angles, max_angles: float2; dir: float3) : float2
  let SAFE_HALF_PI = PI * 0.5 - 1e-3f
  let maxAngleX = min(deg_to_rad(max_angles.x), SAFE_HALF_PI)
  let maxAngleY = min(deg_to_rad(max_angles.y), SAFE_HALF_PI)
  let dirAngles: float2 = dir_to_angles(dir)
  return float2(
    clamp_s_ang(angles.x, dirAngles.x - maxAngleX, dirAngles.x + maxAngleX),
    clamp_s_ang(angles.y, dirAngles.y - maxAngleY, dirAngles.y + maxAngleY)
  )

[generic]
def make_rot_cw_zyx(angles: float3) : float3x4
  var tmX, tmY, tmZ : float3x4
  rotxTM(angles.x, tmX)
  rotyTM(angles.y, tmY)
  rotzTM(angles.z, tmZ)
  return tmZ * tmY * tmX