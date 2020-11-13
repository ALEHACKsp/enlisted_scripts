require ecs
require app
require statBQ
require jsonwriter
require game.es.events
require game.es.stat_bq_common

[private]
def isTeamsSwithed() : bool
  var result = false
  query() <| $[es](isTeamsSwitched: bool) { result = isTeamsSwitched; }
  return result

[es (tag=server, on_event=EventLevelLoaded, REQUIRE=level_dot_blk)]
def session_stated_es(evt: Event)
  send_event_bq_with_header("session_start") <| $(var jw: JsonWriter)
    jw_key_value(jw, "level", get_current_scene())

[es (tag=server, on_event=EventEntityDestroyed, REQUIRE=level_dot_blk)]
def session_end_es(evt: Event)
  send_event_bq_with_header("session_stop") <| $(var jw: JsonWriter)
    jw_key_value(jw, "level", get_current_scene())
    jw_key_value(jw, "teams_switched", isTeamsSwithed())

[es (tag=server, REQUIRE=level_dot_blk)]
def session_on_round_end_es(evt: EventTeamRoundResult)
  send_event_bq_with_header("session_stop_with_result") <| $(var jw: JsonWriter)
    jw_key_value(jw, "level", get_current_scene())
    jw_key_value(jw, "team", evt.team)
    jw_key_value(jw, "is_won", evt.isWon)
    jw_key_value(jw, "teams_switched", isTeamsSwithed())

    let team = evt.team
    ecs::find_query() <| $[es](team_dot_id: int; team_dot_score: float; team_dot_scoreCap: float; team_dot_army: string)
      let isMyTeam = team_dot_id == team
      if isMyTeam
        jw_key_value(jw, "army", team_dot_army)
        jw_key_value(jw, "team_score", team_dot_score)
        jw_key_value(jw, "team_score_cap", team_dot_scoreCap)
      return isMyTeam
