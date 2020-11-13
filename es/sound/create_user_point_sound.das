require app
require ecs
require soundHash
require game.es.sound.sound_events

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server)]
def create_user_point_sound_es(evt : Event;
                               userPointOwner : ecs::EntityId;
                               userPointType : string;
                               transform : float3x4)
  if userPointType != ""
    query(userPointOwner) <| $ [es] (var possessed : ecs::EntityId)
      sendEvent(possessed, [[CmdPlayNetSound hash=sound_hash("uiMap_{userPointType}"), pos=transform[3], param=0., interval=0., time=get_sync_time()]])
