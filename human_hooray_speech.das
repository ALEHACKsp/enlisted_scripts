require ecs
require app
require math
require math.base
require DagorRandom
require HumanPhys
require soundHash
require game.es.sound.sound_events
require player

def is_facing_target(cur_pos : float3 const&; cur_dir : float3 const&; cur_team : int)
  var isTowardsAny : bool = false
  var isInsideAny : bool = false
  ecs::query() <| $ [es] (transform : float3x4; capzone_dot_owningTeam : int; active : bool; sphere_zone_dot_radius = 0.0)
    if (active && capzone_dot_owningTeam != cur_team)
      var zonePos = transform[3]
      if distance_sq(zonePos, cur_pos) < square(sphere_zone_dot_radius)
        isInsideAny = true
      elif dot(cur_dir, normalize(zonePos - cur_pos)) > 0.5
        isTowardsAny = true
  return isTowardsAny && !isInsideAny


def get_team_size(cur_eid : ecs::EntityId; cur_team : int; cur_pos : float3 const&)
  var teamSize:float = 0.0
  ecs::query() <| $ [es](eid : ecs::EntityId;
                         team:int;
                         transform:float3x4;
                         human_hooray_speech_dot_radius : float)
    if team == cur_team && eid != cur_eid
      if distance_sq(cur_pos, transform[3]) < human_hooray_speech_dot_radius * human_hooray_speech_dot_radius
        ++teamSize
  return teamSize


[es (tag=server, no_order)]
def human_hooray_speech_es(info : UpdateStageInfoAct; eid : ecs::EntityId;
                           human_net_phys_dot_curMoveState : int;
                           var human_hooray_speech_dot_lookup : float &;
                           var human_hooray_speech_dot_sensitivity : float &;
                           human_hooray_speech_dot_restore : float;
                           var human_hooray_speech_dot_morale : float &;
                           human_hooray_speech_dot_decay : float;
                           human_hooray_speech_dot_threshold : float;
                           var human_hooray_speech_dot_delay : float &;
                           var human_hooray_speech_dot_timer : float &;
                           transform:float3x4;
                           team:int)
  human_hooray_speech_dot_timer = max(0.0, human_hooray_speech_dot_timer - info.dt)
  if human_hooray_speech_dot_delay > 0.0
    human_hooray_speech_dot_delay -= info.dt
    return

  if human_hooray_speech_dot_morale >= human_hooray_speech_dot_threshold
    sendEvent(eid, [[CmdRequestHumanSpeech phrase=sound_hash("hooray"), threshold=1.]])
    let curTeam = team
    let curPos = transform[3]
    let curMorale = human_hooray_speech_dot_morale
    ecs::query() <| $ [es](team:int;
                           transform:float3x4;
                           var human_hooray_speech_dot_morale : float &;
                           var human_hooray_speech_dot_delay : float &;
                           human_hooray_speech_dot_delayMinMax : float2;
                           human_hooray_speech_dot_sensitivity : float;
                           human_hooray_speech_dot_radius : float)
      if team == curTeam
        if distance_sq(curPos, transform[3]) < human_hooray_speech_dot_radius * human_hooray_speech_dot_radius
          human_hooray_speech_dot_morale += curMorale * human_hooray_speech_dot_sensitivity
          if human_hooray_speech_dot_delay < 0.0
            human_hooray_speech_dot_delay = rnd_float(human_hooray_speech_dot_delayMinMax.x, human_hooray_speech_dot_delayMinMax.y)
    human_hooray_speech_dot_morale = 0.0
    human_hooray_speech_dot_sensitivity = 0.0

  if human_net_phys_dot_curMoveState == int(HUMoveState EMS_SPRINT) && human_hooray_speech_dot_timer > 0.0
    human_hooray_speech_dot_lookup += info.dt
    if human_hooray_speech_dot_lookup >= 1.0
      human_hooray_speech_dot_lookup = 0.0
      if is_facing_target(transform[3], transform[0], team)
        human_hooray_speech_dot_morale += min(get_team_size(eid, team, transform[3]), 3.0) * human_hooray_speech_dot_sensitivity
  else
    human_hooray_speech_dot_morale = max(0.0, human_hooray_speech_dot_morale - info.dt * human_hooray_speech_dot_decay)
  human_hooray_speech_dot_sensitivity = min(human_hooray_speech_dot_sensitivity + info.dt * human_hooray_speech_dot_restore, 1.0)


[es (tag=server, on_event=CmdHumanHoorayRequest)]
def on_human_hooray_request(evt : Event;
                            var human_hooray_speech_dot_morale : float &;
                            human_hooray_speech_dot_append : float)
  human_hooray_speech_dot_morale += human_hooray_speech_dot_append
