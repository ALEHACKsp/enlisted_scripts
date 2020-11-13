options remove_unused_symbols = false
module ai_danger_common
require ecs
require walkerai
require math
require math.base
require EnlistedWalkerai

[generic]
def logistic(x : float; k = 1.; max = 1.)
  return max / (1. + exp(-k * x))

[generic]
def logistic(x : float; coef : float3 /* k, max, x offset */)
  return logistic(x + coef.z, coef.x, coef.y)

[generic]
def inv(x : float; coef : float2)
  return coef.y * min(coef.x, safeinv(x))

[generic]
def calc_target_alertness(dist : float; frustum_cos : float;
                          agent_dangers_dot_maxDangerDist : float;
                          dist_coef : float2 = float2(-0.03, 0.77);
                          frustum_coef : float3 = float3(5., 1f, 0.);
                          frustum_offset : float2 = float2(-0.1, 0.23)) : float
  let distK = logistic(dist, float3(dist_coef.x, dist_coef.y, -agent_dangers_dot_maxDangerDist))
  let frustumK = frustum_offset.y * (logistic(frustum_cos, frustum_coef) + frustum_offset.x)
  return saturate(distK + frustumK)

[generic]
def time_to_dt(cur_time : float; time : float; defVal : float)
  return time < 0f ? defVal : cur_time - time

[generic]
def calc_danger(cur_time, agent_dangers_dot_maxDangerDist : float; danger : Danger; ai_target : Target; is_ai : bool;
                ai_coef : float2 = float2(1., 1.);
                downed_coef : float2 = float2(1., 1.1);
                avoid_bullets_near_time : float = 10f;
                distance_coef : float3 = float3(-0.5, 4., 0.);
                in_frustum_coef : float3 = float3(0.5, 2., 0.);
                last_shoot_coef : float2 = float2(10., 1.);
                last_kill_coef : float2 = float2(10., 3.);
                noise_coef : float2 = float2(0.2, 1f);
                last_bullet_nearby_coef : float2 = float2(10f, 10f)) : float
  let aiK = is_ai ? ai_coef.x : ai_coef.y
  let downedK = ai_target.isDowned ? downed_coef.x : downed_coef.y
  let distMult = danger.distance <= agent_dangers_dot_maxDangerDist || cur_time - danger.lastBulletNearbyTime < avoid_bullets_near_time ? 1f : 0f
  let nearK = logistic(danger.distance, distance_coef)
  let distK = (
      nearK
    + logistic(time_to_dt(cur_time, danger.inFrustumTime, 0f), in_frustum_coef) * downedK
    + inv(ai_target.lastShootTimer, last_shoot_coef)
    + inv(ai_target.lastKillTimer, last_kill_coef)
  )
  let noiseK = noise_coef.x * ai_target.noiseLevel + noise_coef.y
  return danger.alertness * distMult * distK * noiseK * aiK + inv(time_to_dt(cur_time, danger.lastBulletNearbyTime, 1e8), last_bullet_nearby_coef)

[generic]
def calc_noise(cur_time, agent_dangers_dot_maxDangerDist : float; danger : Danger; ai_target : Target;
                avoid_bullets_near_time : float = 10f;
                distance_coef : float3 = float3(-0.5, 4., 0.);
                last_shoot_coef : float2 = float2(10., 1.);
                last_kill_coef : float2 = float2(10., 3.);
                noise_coef : float2 = float2(0.2, 1f);
                last_bullet_nearby_coef : float2 = float2(10f, 10f)) : float
  let distMult = danger.distance <= agent_dangers_dot_maxDangerDist || cur_time - danger.lastBulletNearbyTime < avoid_bullets_near_time ? 1f : 0f
  let nearK = logistic(danger.distance, distance_coef)
  let distK = (
      nearK
    + inv(ai_target.lastShootTimer, last_shoot_coef)
    + inv(ai_target.lastKillTimer, last_kill_coef)
  )
  let noiseK = noise_coef.x * ai_target.noiseLevel + noise_coef.y
  return danger.alertness * distMult * distK * noiseK + inv(time_to_dt(cur_time, danger.lastBulletNearbyTime, 1e8), last_bullet_nearby_coef)

[generic]
def calc_traceable_ratio(cur_time : float; dangerMeter : float; danger : Danger) : float
  let timeMult = min(5f, cur_time - danger.lastTraceTime)
  return dangerMeter * timeMult
