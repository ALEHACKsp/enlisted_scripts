require ecs
require statBQ
require jsonwriter
require game.es.events
require game.es.stat_bq_common
require player

[private]
def on_zone_captured(evt, eid, capzone_dot_title)
  if eid == evt.zone
    send_event_bq_with_header("zone_capture") <| $(var jw: JsonWriter)
      jw_key_value(jw, "capzone_id", capzone_dot_title)
      jw_key_value(jw, "team", evt.team)

[es (tag=server)]
def zone_is_about_to_be_captured_es(evt: EventZoneIsAboutToBeCaptured; eid: EntityId; capzone_dot_title: string)
  on_zone_captured(evt, eid, capzone_dot_title)

[es (tag=server)]
def zone_captured_es(evt: EventZoneCaptured; eid: EntityId; capzone_dot_title: string)
  on_zone_captured(evt, eid, capzone_dot_title)

[es (tag=server)]
def zone_decaptured_es(evt: EventZoneDecaptured; eid: EntityId; capzone_dot_title: string)
  if eid == evt.zone
    send_event_bq_with_header("zone_decapture") <| $(var jw: JsonWriter)
      jw_key_value(jw, "capzone_id", capzone_dot_title)
      jw_key_value(jw, "team", evt.team)
