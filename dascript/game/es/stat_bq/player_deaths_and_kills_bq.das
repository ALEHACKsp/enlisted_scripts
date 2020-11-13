require ecs
require statBQ
require jsonwriter
require game.es.events
require game.es.stat_bq_common
require dm

def add_type_and_pos(var jw; eid; prefix)
  ecs::query(eid) <| $[es](transform: float3x4)
    jw_key_value(jw, "{prefix}_pos", "{transform[3]}")
    add_entity_type(jw, eid, prefix)

def get_event_type(evt; eid)
  if eid == evt.offenderPlayer
    return "player_kill"
  elif eid == evt.victimPlayer
    return "player_death"
  return ""

[es (tag=server, REQUIRE=player)]
def player_kills_and_deaths_es(evt: EventAnyEntityDied; eid: ecs::EntityId; userid: int64)
  let eventType = get_event_type(evt, eid)
  if eventType == "" || userid == int64(-1)
    return

  var victimUserId = int64(-1)
  var offenderUserId = int64(-1)

  ecs::query(evt.victimPlayer)   <| $[es](userid: int64) { victimUserId   = userid; }
  ecs::query(evt.offenderPlayer) <| $[es](userid: int64) { offenderUserId = userid; }

  if victimUserId == int64(-1) || offenderUserId == int64(-1)
    return

  let gunPropsId = int(evt.deathDesc.gunPropsId)
  send_event_bq_with_header(eventType) <| $(var jw: JsonWriter)
    add_user_id(jw, offenderUserId)
    jw_key_value(jw, "weapon_type", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item.weapType") : "")
    jw_key_value(jw, "weapon_template", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item.weapTemplate") : "")
    jw_key_value(jw, "damage_type", "{evt.deathDesc.damageType}")
    add_user_id(jw, victimUserId, "victim_user_id")

    add_type_and_pos(jw, evt.offender, "offender")
    add_type_and_pos(jw, evt.victim, "victim")
