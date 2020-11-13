require ecs
require soundHash
require game.es.sound.sound_events

[es (tag=sound, on_event=EventEntityDowned, REQUIRE=humanSound)]
def human_downed_coverme_speech_es(evt:Event; eid:ecs::EntityId)
  sendEvent(eid, [[CmdRequestHumanSpeech phrase=sound_hash("coverme"), threshold=1.]])
