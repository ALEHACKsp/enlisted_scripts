require ecs
require statBQ
require game.es.stat_bq_common
require ECSGlobalTags
require game.es.app_common

[es (tag=server, on_event=EventLevelLoaded, REQUIRE=level_dot_blk)]
def send_aot_stat_on_session_start(evt: Event)
  // if is_production_circuit() // TODO: uncomment after test
  send_event_bq_with_header("dascript_stats") <| $(var jw: JsonWriter)
    jw_key_value(jw, "das_systems_count", das_ecs_systems_count())
    jw_key_value(jw, "das_aot_systems_count", das_ecs_aot_systems_count())
    jw_key_value(jw, "link_aot_errors_count", link_aot_errors_count())
