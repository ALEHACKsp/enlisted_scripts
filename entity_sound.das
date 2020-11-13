require ecs
require soundSystem
require math

[es (tag=sound, after=animchar_render_es)]
def entity_sound_es(info:UpdateStageInfoAct;
                    var entity_sound_dot_inRange : bool&;
                    load_sound_dot_isLoaded : bool;
                    entity_sound_dot_range : float;
                    transform : float3x4;
                    var entity_sound_dot_enabled : bool&)
  let distSq = distance_sq(get_listener_pos(), transform[3])
  let multiplierSq = 0.9 * 0.9
  entity_sound_dot_inRange = entity_sound_dot_inRange ? (distSq < entity_sound_dot_range * entity_sound_dot_range) : (distSq < entity_sound_dot_range * entity_sound_dot_range * multiplierSq)
  entity_sound_dot_enabled = entity_sound_dot_inRange && load_sound_dot_isLoaded
