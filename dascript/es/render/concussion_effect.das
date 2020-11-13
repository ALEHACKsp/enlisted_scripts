require ecs
require app
require DagorShaders

let
  concsussion_effect_time_startVarId = get_shader_variable_id("concussion_effect_time_start", true)
  concussion_effect_durationVarId = get_shader_variable_id("concussion_effect_duration", true)

[es (tag=render, REQUIRE=hero, track=hasConcussedVision, on_event=EventComponentsAppear)]
def track_concussion_vision(evt : Event; eid : EntityId; hasConcussedVision : bool)
  if !hasConcussedVision
    DagorShaders::set_real(concsussion_effect_time_startVarId, -1000.0)
    return

  find_query() <| $ [es (REQUIRE=concussionScreenEffect)] (game_effect_dot_attachedTo: EntityId;
                                                           concussion_dot_startedAtTime : float;
                                                           concussion_dot_duration : float)
    if game_effect_dot_attachedTo != eid
      return false
    let durationLeft = concussion_dot_duration - (get_sync_time() - concussion_dot_startedAtTime)
    DagorShaders::set_real(concsussion_effect_time_startVarId, get_shader_global_time_phase(0.0, 0.0))
    DagorShaders::set_real(concussion_effect_durationVarId, durationLeft)
    return true
