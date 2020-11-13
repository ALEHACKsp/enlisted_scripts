require ecs
require AnimV20
require game.es.node_attach

[es (on_event=(EventEntityCreated, EventComponentsAppear))]
def flamethrower_init_effect(evt : Event;
                             animchar : AnimcharBaseComponent;
                             flamethrower_dot_streamEffectNodeName : string;
                             var flamethrower_dot_streamEffectNodeIdx: int&)
  flamethrower_dot_streamEffectNodeIdx = animchar_find_node_index(animchar, flamethrower_dot_streamEffectNodeName);

[es (tag=gameClient, track=flamethrower_dot_active)]
def flamethrower_manage_stream_effect(evt : Event;
                                      eid : EntityId;
                                      animchar : AnimcharBaseComponent;
                                      flamethrower_dot_active : bool;
                                      flamethrower_dot_streamEffectTemplate : string;
                                      flamethrower_dot_streamEffectNodeIdx : int;
                                      var flamethrower_dot_streamEffectEid : EntityId&)
  if flamethrower_dot_active
    if !flamethrower_dot_streamEffectEid
      flamethrower_dot_streamEffectEid = createEntity(flamethrower_dot_streamEffectTemplate) <| $ (var init: ComponentsInitializer)
        var tm : float3x4
        animchar_get_node_wtm(animchar, flamethrower_dot_streamEffectNodeIdx, tm)
        set(init, "transform", tm)
      attach_to_node(flamethrower_dot_streamEffectEid, eid, flamethrower_dot_streamEffectNodeIdx)
  elif flamethrower_dot_streamEffectEid != INVALID_ENTITY_ID
    destroyEntity(flamethrower_dot_streamEffectEid)
    flamethrower_dot_streamEffectEid = INVALID_ENTITY_ID

[es (tag=server, track=human_gun_attached)]
def flamethrower_disable_unattached(evt : Event;
                                    human_gun_attached : bool;
                                    var flamethrower_dot_active : bool&)
  if !human_gun_attached
    flamethrower_dot_active = false
