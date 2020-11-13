require ecs
require app
require soundHash
require soundSystem
require soundEvent
require game.es.sound.sound_events
require game.es.sound.sound_desc
require game.es.sound.sound_player

def get_npc_voice(voice_id : int; npc_voices : ecs::Array)
  if npc_voices.empty || voice_id < 0
    return ""
  let pEcsStr = get_ecs_string(npc_voices[voice_id % int(npc_voices.size)])
  return pEcsStr != null ? string(*pEcsStr) : ""

def start_speech(phrase_id : int;
                 human_speech_dot_canSpeak : bool;
                 human_sound_dot_playerVoice : string;
                 human_sound_dot_npcVoices : ecs::Array;
                 human_sound_dot_voiceId : int;
                 human_speech_dot_speeches : ecs::Array;
                 is_watched_sound : bool;
                 var sound_group : IPoint3List;
                 transform : float3x4;
                 human_speech_dot_distThreshold = 50.0)
  if !is_watched_sound && !soundEvent::should_play(transform[3], human_speech_dot_distThreshold)
    return
  if human_speech_dot_canSpeak && phrase_id >= 0 && phrase_id < int(human_speech_dot_speeches.size)
    let desc = get_ecs_object(human_speech_dot_speeches[phrase_id])
    if desc != null
      let h = sound_player::get_sound(sound_group, sound_hash("speech"))
      if soundEvent::is_playing(h) && (get_int(desc, "priority") ?? -1) >= 0
        return
      let path = is_watched_sound ? human_sound_dot_playerVoice : get_npc_voice(human_sound_dot_voiceId, human_sound_dot_npcVoices)
      sound_player::play_desc_path(*desc, path, sound_hash("speech"), transform[3], sound_group, is_watched_sound, true, 0.0)

[es (tag=sound)]
def on_cmd_human_speech_es(evt:CmdHumanSpeech;
                           human_speech_dot_canSpeak : bool;
                           human_sound_dot_playerVoice : string;
                           human_sound_dot_npcVoices : ecs::Array;
                           human_sound_dot_voiceId : int;
                           human_speech_dot_speeches : ecs::Array;
                           is_watched_sound : bool;
                           var sound_group : IPoint3List;
                           transform : float3x4)
  if get_sync_time() < evt.time + 5.0
    start_speech(evt.phraseId,
                 human_speech_dot_canSpeak,
                 human_sound_dot_playerVoice,
                 human_sound_dot_npcVoices,
                 human_sound_dot_voiceId,
                 human_speech_dot_speeches,
                 is_watched_sound,
                 sound_group,
                 transform)

[es (tag=sound)]
def on_cmd_human_team_speech_es(evt:CmdHumanTeamSpeech;
                                human_speech_dot_canSpeak : bool;
                                human_sound_dot_playerVoice : string;
                                human_sound_dot_npcVoices : ecs::Array;
                                human_sound_dot_voiceId : int;
                                human_speech_dot_speeches : ecs::Array;
                                is_watched_sound : bool;
                                var sound_group : IPoint3List;
                                transform : float3x4)
  if get_sync_time() < evt.time + 5.0
    start_speech(evt.phraseId,
                 human_speech_dot_canSpeak,
                 human_sound_dot_playerVoice,
                 human_sound_dot_npcVoices,
                 human_sound_dot_voiceId,
                 human_speech_dot_speeches,
                 is_watched_sound,
                 sound_group,
                 transform)

[es (tag=sound)]
def on_cmd_human_player_speech_es(evt:CmdHumanPlayerSpeech;
                                  human_speech_dot_canSpeak : bool;
                                  human_sound_dot_playerVoice : string;
                                  human_sound_dot_npcVoices : ecs::Array;
                                  human_sound_dot_voiceId : int;
                                  human_speech_dot_speeches : ecs::Array;
                                  is_watched_sound : bool;
                                  var sound_group : IPoint3List;
                                  transform : float3x4)
  if get_sync_time() < evt.time + 5.0
    start_speech(evt.phraseId,
                 human_speech_dot_canSpeak,
                 human_sound_dot_playerVoice,
                 human_sound_dot_npcVoices,
                 human_sound_dot_voiceId,
                 human_speech_dot_speeches,
                 is_watched_sound,
                 sound_group,
                 transform)

[es (tag=sound)]
def on_cmd_hero_speech_es(evt:CmdHeroSpeech;
                          human_speech_dot_canSpeak : bool;
                          human_sound_dot_playerVoice : string;
                          human_sound_dot_npcVoices : ecs::Array;
                          human_sound_dot_voiceId : int;
                          human_speech_dot_speeches : ecs::Array;
                          is_watched_sound : bool;
                          var sound_group : IPoint3List;
                          transform : float3x4)
  let phraseId = find_desc_id("speech", evt.phrase, human_speech_dot_speeches)
  if phraseId >= 0
    start_speech(phraseId,
                 human_speech_dot_canSpeak,
                 human_sound_dot_playerVoice,
                 human_sound_dot_npcVoices,
                 human_sound_dot_voiceId,
                 human_speech_dot_speeches,
                 is_watched_sound,
                 sound_group,
                 transform)
  else
    soundSystem::debug("There is no human speech desc for phrase '{evt.phrase}'")

[es (tag=sound, after=human_sound_es)]
def human_speech_can_speak_es(info : UpdateStageInfoAct;
                              human_speech_dot_enable : bool;
                              human_fall_sound_dot_isFalling : bool;
                              human_net_phys_dot_isUnderwater : bool;
                              human_net_phys_dot_isHoldBreath : bool;
                              var human_speech_dot_canSpeak : bool &;
                              var sound_group : IPoint3List;
                              isAlive : bool;
                              isDowned : bool = false;
                              burning_dot_isBurning : bool = false)
  if human_speech_dot_enable
    let couldSpeak = human_speech_dot_canSpeak
    human_speech_dot_canSpeak = isAlive && !(isDowned ||
                                            human_fall_sound_dot_isFalling ||
                                            human_net_phys_dot_isHoldBreath ||
                                            human_net_phys_dot_isUnderwater ||
                                            burning_dot_isBurning)
    if !human_speech_dot_canSpeak && couldSpeak
      sound_player::abandon_sound(sound_group, sound_hash("speech"))
