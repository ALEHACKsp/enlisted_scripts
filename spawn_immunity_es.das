require ecs
require math
require math.base

[es(no_order)]
def spawn_immunity_es(info : UpdateStageInfoAct;
                      var hitpoints_dot_dmgMult : float&;
                      var spawn_immunity_dot_timer : float&;
                      transform : float3x4;
                      spawn_immunity_dot_initialPos : float3 const&;
                      spawn_immunity_dot_immuneDistance : float = 5.0f)
  if hitpoints_dot_dmgMult >= 1.0f && spawn_immunity_dot_timer < 0.0f
    return

  spawn_immunity_dot_timer -= info.dt

  if spawn_immunity_dot_timer < 0.0f
    hitpoints_dot_dmgMult = 1.0f
    return

  var distSq = distance_sq(spawn_immunity_dot_initialPos, transform[3])
  hitpoints_dot_dmgMult = distSq > square(spawn_immunity_dot_immuneDistance) ? 1.0f : 0.0f

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def spawn_immunity_init_es(evt : Event;
                           var spawn_immunity_dot_initialPos : float3&;
                           transform : float3x4)
  spawn_immunity_dot_initialPos = transform[3];
