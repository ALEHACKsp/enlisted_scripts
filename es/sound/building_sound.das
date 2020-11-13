require app
require ecs
require soundHash
require game.es.sound.sound_events

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server, REQUIRE_NOT=builder_preview)]
def create_building_sound_es(evt : Event;
                             buildingSoundTag : string;
                             transform : float3x4;
                             buildByPlayer : ecs::EntityId)
  if buildingSoundTag != "" && buildByPlayer != ecs::INVALID_ENTITY_ID
    broadcastEvent([[CmdPlayCommonNetSound hash=sound_hash("createBuilding_{buildingSoundTag}"), pos=transform[3], time=get_sync_time()]])
