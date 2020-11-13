require ecs
require ecs.common
require statBQ
require jsonwriter
require DagorSystem
require game.es.events
require game.es.stat_bq_common

def get_squad_object(squad_dot_id; squads): Object const?
  if squad_dot_id < 0 || squad_dot_id >= length(squads)
    logerr("[BQ]: Squad with id {squad_dot_id} does not exist.")
    return null
  return get_ecs_object(squads[squad_dot_id])

def get_squad(squad_dot_id; team_army; armies): Object const?
  let squads = get_army_squads(armies, team_army)
  return squads != null ? get_squad_object(squad_dot_id, *squads) : null

def get_squad_name(squad_dot_id; team_army; armies): string
  let squad = get_squad(squad_dot_id, team_army, armies)
  return squad != null ? get_string(squad, "squadId", "") : ""

def get_squad_vehicle(squad_dot_id; team_army; armies): string
  let squad = get_squad(squad_dot_id, team_army, armies)
  return squad != null ? get_squad_vehicle(squad) : ""

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def squad_spawn_es(evt: Event; squad_dot_id: int; squad_dot_ownerPlayer: ecs::EntityId)
  ecs::query(squad_dot_ownerPlayer) <| $[es](userid: int64; team: int; armies: ecs::Object)
    if userid == int64(-1)
      return
    send_event_bq_with_header("squad_spawn") <| $(var jw: JsonWriter)
      let teamArmy = get_team_army(team)
      add_user_id(jw, userid)
      jw_key_value(jw, "team", team)
      jw_key_value(jw, "army", teamArmy)
      jw_key_value(jw, "squad_id", get_squad_name(squad_dot_id, teamArmy, armies))
      jw_key_value(jw, "squad_vehicle", get_squad_vehicle(squad_dot_id, teamArmy, armies))
