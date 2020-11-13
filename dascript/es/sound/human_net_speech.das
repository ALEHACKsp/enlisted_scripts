require ecs
require app
require soundHash
require game.utils.team
require math
require DagorRandom
require DagorSystem
require DagorMath
require game.es.events
require game.es.sound.sound_events
require game.es.sound.sound_desc

def get_speech_time(idx:int; time:FloatList)
  return idx < length(time) ? time[idx] : 0.

def set_speech_time(idx:int; cur:float; var time:FloatList&)
  assert(idx < 999)
  while idx >= length(time)
    push_back(time, -1000.)
  time[idx] = cur

def is_alone(phrase_id:int; cur_eid:ecs::EntityId; cur_pos:float3; cur_team:int; max_radius:float; var max_time:float&)
  if cur_team == TEAM_UNASSIGNED
    return true
  var isAlone:bool=true
  ecs::query() <| $ [es](eid:ecs::EntityId; team:int; transform:float3x4; human_net_speech_dot_time:FloatList; isAlive:bool)
    if isAlive && team == cur_team && distance_sq(cur_pos, transform[3]) < max_radius * max_radius
      max_time = max(get_speech_time(phrase_id, human_net_speech_dot_time), max_time)
      if eid != cur_eid
        isAlone = false
  return isAlone

def is_disable_after_prev_speech(desc:ecs::Object; speeches:ecs::Array; time:FloatList)
  let comp = desc["disableAfterSpeech"]
  if comp != null
    for it in *get_ecs_array(*comp)
      let obj = get_ecs_object(it)
      let otherName = get_ecs_string(*((*obj)["name"]))
      if otherName != null
        let otherTime = get_float(*((*obj)["time"])) ?? 10.
        let otherPhraseId = find_desc_id("speech", string(*otherName), speeches)
        if otherPhraseId >= 0 && get_sync_time() < get_speech_time(otherPhraseId, time) + otherTime
          return true
  return false

def try_speak_impl(phrase_id:int; desc:ecs::Object; var time:FloatList&; team:int; pos:float3; eid:ecs::EntityId; timeThreshold:float=1.)
  let teamRange = get_float(desc, "teamRange") ?? 0.
  let teamOnly = get_bool(desc, "teamOnly") ?? false
  let playerOnly = get_bool(desc, "playerOnly") ?? false
  let minMaxTime = get_Point2(desc, "minMaxTime") ?? float2(0., 0.)
  let curTime = get_sync_time()
  let speechTime = get_speech_time(phrase_id, time)
  if curTime < speechTime + minMaxTime.x
    return
  var teamSpeechTime:float = speechTime
  if teamRange > 0. && is_alone(phrase_id, eid, pos, team, teamRange, teamSpeechTime)
    return // there is no friends around to complain to :(
  let teamSpeechInterval = curTime - teamSpeechTime
  if teamSpeechInterval < minMaxTime.x
    return
  if timeThreshold <= cvt(teamSpeechInterval, minMaxTime.x, minMaxTime.y, 1., 0.)
    return
  set_speech_time(phrase_id, curTime, time)
  if playerOnly
    sendEvent(eid, [[CmdHumanPlayerSpeech phraseId=phrase_id, time=curTime]])
  elif teamOnly
    sendEvent(eid, [[CmdHumanTeamSpeech phraseId=phrase_id, time=curTime]])
  else
    sendEvent(eid, [[CmdHumanSpeech phraseId=phrase_id, time=curTime]])


def take_a_chance(chance:int)
  return chance >= rnd_int(0, 100)

def try_speak(phrase:string; speeches:ecs::Array; var time:FloatList&; team:int; pos:float3; eid:ecs::EntityId; timeThreshold:float=1.)
  let phraseId = find_desc_id("speech", phrase, speeches)
  let desc = get_desc(phraseId, speeches)
  if desc != null && take_a_chance(get_int(desc, "chance") ?? 100) && !is_disable_after_prev_speech(*desc, speeches, time)
    try_speak_impl(phraseId, *desc, time, team, pos, eid, timeThreshold)

def try_speak(phraseHash:uint; speeches:ecs::Array; var time:FloatList&; team:int; pos:float3; eid:ecs::EntityId; timeThreshold:float=1.)
  let phraseId = find_desc_id("speech", phraseHash, speeches)
  let desc = get_desc(phraseId, speeches)
  if desc != null && take_a_chance(get_int(desc, "chance") ?? 100) && !is_disable_after_prev_speech(*desc, speeches, time)
    try_speak_impl(phraseId, *desc, time, team, pos, eid, timeThreshold)


[es (tag=server)]
def on_request_human_net_speech_es(evt:CmdRequestHumanSpeech; eid:ecs::EntityId;
                                   human_speech_dot_speeches:ecs::Array;
                                   var human_net_speech_dot_time:FloatList&;
                                   team:int=TEAM_UNASSIGNED;
                                   transform:float3x4;
                                   isAlive, isDowned:bool)
  if isAlive && (!isDowned || evt.phrase == sound_hash("coverme"))
    try_speak(evt.phrase, human_speech_dot_speeches, human_net_speech_dot_time, team, transform[3], eid, evt.threshold)

[es (on_event=EventWeapOnReload, tag=server)]
def on_weap_reload_human_net_speech_es(evt:Event; eid:ecs::EntityId;
                                       human_speech_dot_speeches:ecs::Array;
                                       var human_net_speech_dot_time:FloatList&;
                                       team:int=TEAM_UNASSIGNED;
                                       transform:float3x4)
  try_speak("reload", human_speech_dot_speeches, human_net_speech_dot_time, team, transform[3], eid)
