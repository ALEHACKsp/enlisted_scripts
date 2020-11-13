require ecs
require math
require DagorSystem
require DagorRandom
require DagorMath
require smokeTracers

[es (tag=render, no_order)]
def background_tracer_es(info : ecs::UpdateStageInfoAct;
                         eid : ecs::EntityId;
                         var background_tracer_dot_pos : float3&;
                         background_tracer_dot_vel : float3;
                         background_tracer_dot_id : int;
                         var background_tracer_dot_ttl : float&)
  assert(background_tracer_dot_id >= 0)
  if (background_tracer_dot_ttl > 0.0)
    background_tracer_dot_pos += background_tracer_dot_vel * info.dt
    background_tracer_dot_ttl -= info.dt
    update_smoke_tracer_pos(uint(background_tracer_dot_id), background_tracer_dot_pos)
  else
    leave_smoke_tracer(uint(background_tracer_dot_id))
    destroyEntity(eid)

[es (tag=render, no_order)]
def tracer_launcher_es(info : ecs::UpdateStageInfoAct;
                       tracer_launcher_dot_short_cooldown : float;
                       tracer_launcher_dot_long_cooldown_probability : float;
                       tracer_launcher_dot_long_cooldown_min_max : float2;
                       tracer_launcher_dot_bullet_size : float;
                       tracer_launcher_dot_bullet_speed : float;
                       tracer_launcher_dot_bullet_ttl : float;
                       tracer_launcher_dot_bullet_color : float3;
                       tracer_launcher_dot_shoot_direction : float2; //angles in spherical coordinates
                       tracer_launcher_dot_rotate_range : float2;
                       tracer_launcher_dot_rotate_speed : float;
                       var tracer_launcher_dot_time_to_fire : float&;
                       transform : float3x4)
  tracer_launcher_dot_time_to_fire -= info.dt;
  if tracer_launcher_dot_time_to_fire > 0.0
    return
  if rnd_float(0.0, 1.0) < tracer_launcher_dot_long_cooldown_probability
    tracer_launcher_dot_time_to_fire += rnd_float(tracer_launcher_dot_long_cooldown_min_max.x,
                                                  tracer_launcher_dot_long_cooldown_min_max.y)
  else
    tracer_launcher_dot_time_to_fire += tracer_launcher_dot_short_cooldown
  let pos = transform[3]
  let t = info.curTime * tracer_launcher_dot_rotate_speed;
  let theta = PI / 180.0 * (tracer_launcher_dot_shoot_direction.x +
                            tracer_launcher_dot_rotate_range.x * sin(t))
  let phi = PI / 180.0 * (tracer_launcher_dot_shoot_direction.y +
                          tracer_launcher_dot_rotate_range.y * cos(1.25 * t))
  var sinTheta, cosTheta, sinPhi, cosPhi : float
  sincos(theta, sinTheta, cosTheta)
  sincos(phi, sinPhi, cosPhi)
  let dir = float3(cosTheta * cosPhi, sinTheta, cosTheta * sinPhi)
  let colorTtl = float4(tracer_launcher_dot_bullet_color.x, tracer_launcher_dot_bullet_color.y,
                        tracer_launcher_dot_bullet_color.z, tracer_launcher_dot_bullet_ttl)
  let smoke = float4(0, 0, 0, 0)
  let id = create_smoke_tracer(pos, dir, tracer_launcher_dot_bullet_size, Color4(smoke), Color4(colorTtl), 0.0001)
  if id < 0
    return
  createEntity("background_tracer") <| $ (var init:ComponentsInitializer)
    set(init, "background_tracer.pos", pos)
    set(init, "background_tracer.vel", dir * tracer_launcher_dot_bullet_speed)
    set(init, "background_tracer.id", id)
    set(init, "background_tracer.ttl", tracer_launcher_dot_bullet_ttl)
