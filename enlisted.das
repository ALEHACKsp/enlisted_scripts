options remove_unused_symbols = false
options no_aot = true//since this is merely loader
module enlisted
require ecs
require game.game
require common_shooter.common_shooter
require app
require ECSGlobalTags


[private]
def load_render() : bool
  var ok = true
  if ecs_has_tag("render") || app::get_game_name() == "aot"
    ok = load_es("enlisted/game/es/render/background_tracers_es.das") && ok
  return ok

[private]
def load_input() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot"
    ok = load_es("enlisted/game/es/input/wallposter_input.das") && ok
  return ok

[init]
def load
  var ok = true
  ok = load_es("enlisted/game/es/enlisted_events.das") && ok
  ok = load_es("enlisted/game/es/squad_cleanup_es.das") && ok
  ok = load_es("enlisted/game/es/squad_members_count_es.das") && ok
  ok = load_es("enlisted/game/es/context_command.das") && ok
  ok = load_es("enlisted/game/es/squad_order.das") && ok
  ok = load_es("enlisted/game/es/squad_mate_order_bring_ammo.das") && ok
  ok = load_es("enlisted/game/es/squad_mate_order_heal.das") && ok
  ok = load_es("enlisted/game/es/squad_mate_order_artillery.das") && ok
  ok = load_es("enlisted/game/es/squad_mate_order.das") && ok
  ok = load_es("enlisted/game/es/squad_member_es_event_handler.das") && ok
  ok = load_es("enlisted/game/es/squad_reset_order_es.das") && ok
  ok = load_es("enlisted/game/es/squad_debug.das") && ok
  ok = load_es("enlisted/game/es/hero_squad_components.das") && ok
  ok = load_es("enlisted/game/es/human_look_at_zone_es.das") && ok
  ok = load_es("enlisted/game/es/sound/human_hooray_speech.das") && ok
  if ecs_has_tag("sound") || app::get_game_name() == "aot"
    ok = load_es("enlisted/game/es/sound/human_coverme_speech.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_shredder.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_seats_damage.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_seats_limited_visibility.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_damage.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_map_icon_es.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_cockpit.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_input.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_debug.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_spawn_validator.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_seats_perks.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_phys_mods.das") && ok
  ok = load_es("enlisted/game/es/disable_respbase_on_hit_es.das") && ok
  ok = load_es("enlisted/game/es/fortifications_build_preview.das") && ok
  ok = load_es("enlisted/game/es/fortifications_build_additive_buildings.das") && ok
  ok = load_es("enlisted/game/es/fortifications_build_minimap_icons.das") && ok
  ok = load_es("enlisted/game/es/fortification_destroyer.das") && ok
  ok = load_es("enlisted/game/es/fortification_action.das") && ok
  ok = load_es("enlisted/game/es/fortification_builder.das") && ok
  ok = load_es("enlisted/game/es/fortifications_preview_time_destroyer.das") && ok
  ok = load_es("enlisted/game/es/wallposter.das") && ok
  ok = load_es("enlisted/game/es/human_hud_marker_visibility_es.das") && ok
  ok = load_es("enlisted/game/es/artillery_radio_es.das") && ok
  ok = load_es("enlisted/game/es/artillery_radio_available.das") && ok
  ok = load_es("enlisted/game/es/animchar_update_disabler.das") && ok
  ok = load_es("enlisted/game/es/animchar_custom_params_applyer.das") && ok
  ok = load_es("enlisted/game/es/artillery_start.das") && ok
  ok = load_es("enlisted/game/es/change_team_es.das") && ok
  ok = load_es("enlisted/game/es/destroy_nonlootable_weapons.das") && ok
  ok = load_es("enlisted/game/es/stat_bq/sessions_bq.das") && ok
  ok = load_es("enlisted/game/es/stat_bq/players_bq.das") && ok
  ok = load_es("enlisted/game/es/stat_bq/squads_bq.das") && ok
  ok = load_es("enlisted/game/es/stat_bq/player_deaths_and_kills_bq.das") && ok
  ok = load_es("enlisted/game/es/stat_bq/captures_bq.das") && ok
  ok = load_es("enlisted/game/es/lut_switcher.das") && ok
  ok = load_es("enlisted/game/es/respawner_es.das") && ok
  ok = load_es("enlisted/game/es/squad_suicide_rate.das") && ok
  ok = load_es("enlisted/game/es/spawn_soldier.das") && ok
  ok = load_es("enlisted/game/es/respawn_camera_es.das") && ok
  ok = load_es("enlisted/game/es/respawn_selector_es.das") && ok
  ok = load_es("enlisted/game/es/respawns_builder.das") && ok
  ok = load_es("enlisted/game/es/respawns_group_in_capture_points.das") && ok
  ok = load_es("enlisted/game/es/artillery_spawn_delay.das") && ok
  ok = load_es("enlisted/game/es/out_battle_area_shredder.das") && ok
  ok = load_es("enlisted/game/es/aircraft/aircraft_shredder.das") && ok
  ok = load_es("enlisted/game/es/aircraft/crew_equipment_hider.das") && ok
  ok = load_es("enlisted/game/es/aircraft/aircraft_identification.das") && ok
  ok = load_es("enlisted/game/es/afk_enable_by_circuit.das") && ok
  ok = load_es("enlisted/game/es/suicide_penalty_enable.das") && ok
  ok = load_es("enlisted/game/es/stat_bq/squad_stats_es.das") && ok
  ok = load_es("enlisted/game/es/capzone.das") && ok
  ok = load_es("enlisted/game/es/capzone_debug.das") && ok
  ok = load_es("enlisted/game/es/autodetect_team.das") && ok
  ok = load_es("enlisted/game/es/vehicle/vehicle_resupply.das") && ok
  ok = load_es("enlisted/game/es/downed_grenade.das") && ok
  ok = load_es("enlisted/game/es/aircraft_debug.das") && ok
  ok = load_es("enlisted/game/es/entities_in_victim_tank_es.das") && ok
  ok = load_es("enlisted/game/es/lock_camera_on_downed.das") && ok
  ok = load_es("enlisted/game/es/ammo_box_es.das") && ok
  ok = load_es("enlisted/game/es/no_bots_mode.das") && ok
  ok = load_render() && ok
  ok = load_input() && ok

  if app::get_game_name() == "aot"
    assert(ok)
