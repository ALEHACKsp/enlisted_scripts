options remove_unused_symbols = false
options no_aot = true//since this is merely loader
module game
require ecs
require app
require ECSGlobalTags
// Common game modules, just require game.game to activate module

[private]
def load_sound() : bool
  var ok = true
  ok = load_es("game/es/sound/loot_net_sound.das") && ok
  ok = load_es("game/es/sound/shell_explode_net_sound.das") && ok
  ok = load_es("game/es/sound/human_net_speech.das") && ok
  ok = load_es("game/es/sound/gun_overheat_human_net_speech.das") && ok
  ok = load_es("game/es/sound/vehicle_net_horn.das") && ok
  ok = load_es("game/es/sound/building_sound.das") && ok
  ok = load_es("game/es/sound/create_user_point_sound.das") && ok
  if ecs_has_tag("sound") || app::get_game_name() == "aot"
    ok = load_es("game/es/sound/building_destroy_sound.das") && ok
    ok = load_es("game/es/sound/human_speech.das") && ok
    ok = load_es("game/es/sound/human_burning_sound.das") && ok
    ok = load_es("game/es/sound/human_use_item_sound.das") && ok
    ok = load_es("game/es/sound/repairable_progress_sound.das") && ok
    ok = load_es("game/es/sound/human_sound_building_action_tag.das") && ok
    ok = load_es("game/es/sound/human_breath_sound.das") && ok
    ok = load_es("game/es/sound/human_climb_sound.das") && ok
    ok = load_es("game/es/sound/human_fall_sound.das") && ok
    ok = load_es("game/es/sound/human_downed_sound.das") && ok
    ok = load_es("game/es/sound/loot_sound.das") && ok
    ok = load_es("game/es/sound/birds_sound.das") && ok
    ok = load_es("game/es/sound/creature_hit_cry_sound.das") && ok
    ok = load_es("game/es/sound/creature_burning_cry_sound.das") && ok
    ok = load_es("game/es/sound/creature_death_sound.das") && ok
    ok = load_es("game/es/sound/play_net_sound.das") && ok
    ok = load_es("game/es/sound/load_sound.das") && ok
    ok = load_es("game/es/sound/entity_sound.das") && ok
    ok = load_es("game/es/sound/environment_sound.das") && ok
    ok = load_es("game/es/sound/clock_chime_ringer.das") && ok
    ok = load_es("game/es/sound/camera_inside_snapshot.das") && ok
    ok = load_es("game/es/sound/install_weap_mod_sound.das") && ok
    ok = load_es("game/es/sound/rendinst_damage_sound.das") && ok
    ok = load_es("game/es/sound/concussion_sound.das") && ok
    ok = load_es("game/es/sound/underwater_sound.das") && ok
    ok = load_es("game/es/sound/creature_move_state_sound.das") && ok
    ok = load_es("game/es/sound/vehicle_horn.das") && ok
    ok = load_es("game/es/sound/plane_hit_sound.das") && ok
    ok = load_es("game/es/sound/plane_dive_siren.das") && ok
    ok = load_es("game/es/sound/door_sound.das") && ok
    ok = load_es("game/es/sound/human_sound_melee.das") && ok
    ok = load_es("game/es/sound/shell_sound.das") && ok
  return ok

[private]
def load_ui() : bool
  var ok = true
  if ecs_has_tag("ui") || app::get_game_name() == "aot"
    ok = load_es("game/es/ui/node_pos.das") && ok
  return ok


[private]
def load_render() : bool
  var ok = true
  if ecs_has_tag("render") || app::get_game_name() == "aot"
    ok = load_es("game/es/render/armor_hit_effect.das") && ok
    ok = load_es("game/es/render/warmup_effects.das") && ok
    ok = load_es("game/es/render/concussion_effect.das") && ok
    ok = load_es("game/es/render/fire_on_screen.das") && ok
    ok = load_es("game/es/render/snow_whitening.das") && ok
    ok = load_es("game/es/render/effect_on_creation.das") && ok
    ok = load_es("game/es/render/effect_on_first_contact.das") && ok
    ok = load_es("game/es/render/killer_outline.das") && ok
    ok = load_es("game/es/render/ri_double_doors_debug.das") && ok
    ok = load_es("game/es/render/wounds.das") && ok
    ok = load_es("game/es/render/cockpit_slits.das") && ok
  return ok


[private]
def load_input() : bool
  var ok = true
  if ecs_has_tag("input") || app::get_game_name() == "aot"
    ok = load_es("game/es/input/detect_input_mode.das") && ok
    ok = load_es("game/es/input/rumble.das") && ok
  return ok


[init]
def load
  var ok = true
  ok = load_es("game/es/platformInit.das") && ok
  ok = load_es("game/es/events.das") && ok
  ok = load_es("game/es/item_drop_es.das") && ok
  ok = load_es("game/es/cam_target_es.das") && ok
  ok = load_es("game/es/interrupt_item_use.das") && ok
  ok = load_es("game/es/lut_switcher.das") && ok
  ok = load_es("game/es/reset_camera_relative_dir.das") && ok
  ok = load_es("game/es/zone_damage_change.das") && ok
  ok = load_es("game/es/track_teampresence.das") && ok
  ok = load_es("game/es/cleanup_on_destroy.das") && ok
  ok = load_es("game/es/generate_inventory_items.das") && ok
  ok = load_es("game/es/track_hero_inventory.das") && ok
  ok = load_es("game/es/ballistic_phys.das") && ok
  ok = load_es("game/es/platform_recoil_mult.das") && ok
  ok = load_es("game/es/heal_count.das") && ok
  ok = load_es("game/es/human_weap_move_recoil_mult_es.das") && ok
  ok = load_es("game/es/user_points_es.das") && ok
  ok = load_es("game/es/calculate_inventory_stats_es.das") && ok
  ok = load_es("game/es/downed_soldier_finisher.das") && ok
  ok = load_es("game/es/bot_player_ai_enabler.das") && ok
  ok = load_es("game/es/vehicle/vehicle_hp.das") && ok
  ok = load_es("game/es/vehicle/vehicle_events.das") && ok
  ok = load_es("game/es/vehicle/disable_gridcoll.das") && ok
  ok = load_es("game/es/vehicle/cam_target_es.das") && ok
  ok = load_es("game/es/vehicle/validate_seat_owners.das") && ok
  ok = load_es("game/es/vehicle/use_vehicle_on_spawn.das") && ok
  ok = load_es("game/es/vehicle/vehicle_track_hero.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_next_seats.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_can_acquire_controls.das") && ok
  ok = load_es("game/es/vehicle/extinguisher.das") && ok
  ok = load_es("game/es/vehicle/vehicle_camera.das") && ok
  ok = load_es("game/es/vehicle/vehicle_maintenance.das") && ok
  ok = load_es("game/es/vehicle/vehicle_under_water.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_damage.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_hatch.das") && ok
  ok = load_es("game/es/vehicle/vehicle_change_seats.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_controls.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_ragdoll_disabler.das") && ok
  ok = load_es("game/es/vehicle/plane_fall_sound_disabler.das") && ok
  ok = load_es("game/es/vehicle/vehicle_hud.das") && ok
  ok = load_es("game/es/vehicle/turret_weap.das") && ok
  ok = load_es("game/es/vehicle/anchor_after_stopping.das") && ok
  ok = load_es("game/es/vehicle/turret_gun_owners_on_change.das") && ok
  ok = load_es("game/es/aircraft/volumetric_damage_debug.das") && ok
  ok = load_es("game/es/aircraft/wreckage_phys_es.das") && ok
  ok = load_es("game/es/aircraft/wreckage_debug.das") && ok
  ok = load_es("game/es/aircraft/maneuver_detector.das") && ok
  ok = load_es("game/es/aircraft/forestall.das") && ok
  ok = load_es("game/es/squad_es.das") && ok
  ok = load_es("game/es/squad_member_es.das") && ok
  ok = load_es("game/es/update_ai_action_es.das") && ok
  ok = load_es("game/es/shooter_camera_modifiers.das") && ok
  ok = load_es("game/es/spawn_immunity_es.das") && ok
  ok = load_es("game/es/riextra_damage.das") && ok
  ok = load_es("game/es/capturer_es.das") && ok
  ok = load_es("game/es/zones_visitor.das") && ok
  ok = load_es("game/es/automatic_pickup_items.das") && ok
  ok = load_es("game/es/component_replication_filter_es.das") && ok
  ok = load_es("game/es/userstats_es.das") && ok
  ok = load_es("game/es/hair_hider_es.das") && ok
  ok = load_es("game/es/animchar_equip_hider_es.das") && ok
  ok = load_es("game/es/animchar_visibility_es.das") && ok
  ok = load_es("game/es/human_use_item.das") && ok
  ok = load_es("game/es/destroy_underwater.das") && ok
  ok = load_es("game/es/beh_tree_debug.das") && ok
  ok = load_es("game/es/ecs_console.das") && ok
  ok = load_es("game/es/fire_source.das") && ok
  ok = load_es("game/es/node_attached_es.das") && ok
  ok = load_es("game/es/molotov.das") && ok
  ok = load_es("game/es/camera_magnification.das") && ok
  ok = load_es("game/es/human_look_dir_camera.das") && ok
  ok = load_es("game/es/das_debug.das") && ok
  ok = load_es("game/es/device_anim.das") && ok
  ok = load_es("game/es/fire_put_out.das") && ok
  ok = load_es("game/es/artillery_strike_es.das") && ok
  ok = load_es("game/es/device_animation_state.das") && ok
  ok = load_es("game/es/human_mods_es.das") && ok
  ok = load_es("game/es/burning_underwater.das") && ok
  ok = load_es("game/es/locks/locked_use_objects.das") && ok
  ok = load_es("game/es/locks/locked_looting.das") && ok
  ok = load_es("game/es/burning.das") && ok
  ok = load_es("game/es/battle_area.das") && ok
  ok = load_es("game/es/poly_battle_area_create.das") && ok
  ok = load_es("game/es/poly_battle_area_create_debug.das") && ok
  ok = load_es("game/es/entity_actions.das") && ok
  ok = load_es("game/es/human_block_sprint.das") && ok
  ok = load_es("game/es/human_restore_stamina_in_vehicle.das") && ok
  ok = load_es("game/es/human_anim_fpv.das") && ok
  ok = load_es("game/es/human_anim_weap.das") && ok
  ok = load_es("game/es/human_anim_bayonet.das") && ok
  ok = load_es("game/es/human/human_force_anim.das") && ok
  ok = load_es("game/es/human_phys_cam_controller.das") && ok
  ok = load_es("game/es/human_breath_timer_es.das") && ok
  ok = load_es("game/es/human_state.das") && ok
  ok = load_es("game/es/human_weap_phys.das") && ok
  ok = load_es("game/es/human_weap_mods.das") && ok
  ok = load_es("game/es/ai/ai_target_update.das") && ok
  ok = load_es("game/es/ai/ai_danger_update.das") && ok
  ok = load_es("game/es/ai/walker_update.das") && ok
  ok = load_es("game/es/ai/walker_nodes.das") && ok
  ok = load_es("game/es/ai/obstacle.das") && ok
  ok = load_es("game/es/ai/obstacle_fire.das") && ok
  ok = load_es("game/es/ai/obstacle_door.das") && ok
  ok = load_es("game/es/ai/obstacle_still.das") && ok
  ok = load_es("game/es/human_stat_track.das") && ok
  ok = load_es("game/es/concussion.das") && ok
  ok = load_es("game/es/concussion_debug.das") && ok
  ok = load_es("game/es/fire_damage.das") && ok
  ok = load_es("game/es/vehicle/vehicle_next_bullet_type_es.das") && ok
  ok = load_es("game/es/vehicle/enter_vehicle.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_kick_from_destroyed.das") && ok
  ok = load_es("game/es/human_use_item_lock_stationary_gun.das") && ok
  ok = load_es("game/es/flamethrower.das") && ok
  ok = load_es("game/es/flamethrower_effect.das") && ok
  ok = load_es("game/es/flamethrower_debug.das") && ok
  ok = load_es("game/es/subsidiary_gun.das") && ok
  ok = load_es("game/es/smoke_occluder.das") && ok
  ok = load_es("game/es/smoke_occluder_debug.das") && ok
  ok = load_es("game/es/shell_contact.das") && ok
  ok = load_es("game/es/aim_debug.das") && ok
  ok = load_es("game/es/swarm_render_creator.das") && ok
  ok = load_es("game/es/shell_orientaion_by_velocity.das") && ok
  ok = load_es("game/es/heal_and_revive_item.das") && ok
  ok = load_es("game/es/server_debug.das") && ok
  ok = load_es("game/es/vehicle/turret_aim_activate_manual_es.das") && ok
  ok = load_es("game/es/perf_stat.das") && ok
  ok = load_es("game/es/vehicle/turret_aim_activate_es.das") && ok
  ok = load_es("game/es/vehicle/vehicle_seats_hide_owners_es.das") && ok
  ok = load_es("game/es/effects/effect_controller.das") && ok
  ok = load_es("game/es/effects/effect_scale_randomizer.das") && ok
  ok = load_es("game/es/effects/push_effect.das") && ok
  ok = load_es("game/es/vehicle/turrets_init.das") && ok
  ok = load_es("game/es/barbed_wire.das") && ok
  ok = load_es("game/es/ri_double_doors.das") && ok
  ok = load_es("game/es/infinite_ammo.das") && ok
  ok = load_es("game/es/hitpoints_debug.das") && ok
  ok = load_es("game/es/pickup_gun_mod.das") && ok
  ok = load_es("game/es/push_door.das") && ok
  ok = load_es("game/es/dascript_aot_bq.das") && ok
  ok = load_es("game/es/human_camera_lock.das") && ok
  ok = load_es("game/es/human_gun_speed_es.das") && ok
  ok = load_es("game/es/weapons/human_collider_damage.das") && ok
  ok = load_es("game/es/human_hit_tagging_es.das") && ok
  ok = load_es("game/es/human_attached_gun.das") && ok
  ok = load_es("game/es/dead_cleanup_es.das") && ok
  ok = load_es("game/es/collision_damage_es.das") && ok
  ok = load_es("game/es/first_contact_dispatcher.das") && ok
  ok = load_es("game/es/stamina_view.das") && ok
  ok = load_es("game/es/repair_es.das") && ok
  ok = load_es("game/es/human_visibility_tracer.das") && ok
  ok = load_es("game/es/human_weight_acceleration.das") && ok
  ok = load_es("game/es/benchmark_update_es.das") && ok
  ok = load_es("game/es/teleport_debug.das") && ok
  ok = load_es("game/es/track_is_alive.das") && ok
  ok = load_input() && ok
  ok = load_sound() && ok
  ok = load_ui() && ok
  ok = load_render() && ok

  if app::get_game_name() == "aot"
    assert(ok)
