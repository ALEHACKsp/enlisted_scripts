options remove_unused_symbols = false
module stat_bq_common
require ecs
require ecs.common
require statBQ
require jsonwriter public

def send_event_bq_with_header(event_type; subexpr)
  send_event_bq("game_events_bq") <| $(var jw: JsonWriter)
    jw_start_array(jw)
    jw_start_obj(jw)
    add_event_bq_header(jw)
    jw_key_value(jw, "event_type", event_type)
    invoke(subexpr, jw)
    jw_end_obj(jw)
    jw_end_array(jw)

    print("[BQ][{event_type}]: {jw.result}\n")

def add_entity_type(var jw; eid; prefix)
  if has(eid, "human")
    ecs::query(eid) <| $[es](beh_tree_dot_enabled: bool; isInVehicle: bool)
      let suffix = isInVehicle ? "_in_vehicle" : ""
      jw_key_value(jw, "{prefix}_type", beh_tree_dot_enabled ? "human_bot{suffix}" : "human{suffix}")
  elif has(eid, "airplane")
    jw_key_value(jw, "{prefix}_type", "airplane")
  elif has(eid, "vehicle")
    jw_key_value(jw, "{prefix}_type", "vehicle")

def get_team_eid(team: int)
  var teamEid = INVALID_ENTITY_ID
  ecs::find_query() <| $[es](eid: EntityId; team_dot_id: int)
    if team_dot_id == team
      teamEid = eid
    return teamEid != INVALID_ENTITY_ID
  return teamEid

[generic]
def get_team_army(team: int) : string
  return get_string(get_team_eid(team), "team.army", "")

[generic]
def get_army_squads(armies; team_army): Array const?
  let armyData = get_ecs_object(armies, team_army)
  return armyData != null ? get_ecs_array(armyData, "squads") : null

[generic]
def get_squad_vehicle(squad: Object const?): string
  let curVehicle = get_ecs_object(squad, "curVehicle")
  return curVehicle != null ? get_string(curVehicle, "gametemplate", "") : ""

[generic]
def add_user_id(var jw; userid: int64; key : string = "user_id")
  if userid > int64(0)
    jw_key_value(jw, key, userid)
