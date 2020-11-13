require ecs
require app
require soundHash
require game.es.sound.sound_events

[es (track=gun_dot_isOverheat, tag=server)]
def gun_overheat_human_net_speech_es(evt:Event;
                                     gun_dot_isOverheat:bool;
                                     gun_dot_owner:ecs::EntityId)
  if gun_dot_isOverheat
    sendEvent(gun_dot_owner, [[CmdRequestHumanSpeech phrase=sound_hash("gunOverheat"), threshold=1.]])
