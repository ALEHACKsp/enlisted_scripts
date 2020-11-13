require ecs
require player
require math
require game.es.events
require game.es.vehicle.vehicle_events
require DagorSystem
require AnimV20

let
  upperHash = ecs_hash("upper")
  lowerHash = ecs_hash("lower")

[es (on_event=(EventEntityCreated))]
def init_force_anim(evt: Event;
                    game_effect_dot_attachedTo: EntityId;
                    game_effect_dot_forceAnimState: string;
                    var game_effect_dot_forceAnimStateId: int&)
  query(game_effect_dot_attachedTo) <| $[es](animchar: AnimcharBaseComponent)
    let animGraph = animchar.animGraph
    if animGraph != null
      game_effect_dot_forceAnimStateId = animgraph_get_state_index(*animGraph, game_effect_dot_forceAnimState)

[es]
def force_anim_state_es(act: UpdateStageInfoAct; game_effect_dot_attachedTo: EntityId; game_effect_dot_forceAnimStateId: int)
  send_change_anim_state_event(game_effect_dot_attachedTo, "lower", lowerHash, game_effect_dot_forceAnimStateId)
  send_change_anim_state_event(game_effect_dot_attachedTo, "upper", upperHash, game_effect_dot_forceAnimStateId)
