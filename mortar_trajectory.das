require ecs
require player
require game.utils.hero
require game.es.events
require DaWeaponProps
require Gun
require EnlistedWeapon
require common_shooter.es.mortar.mortar_common

[es (tag=render, REQUIRE=mortar)]
def mortar_trajectory_calculation(evt : CmdWeapPhysUpdate;
                                  gun_dot_curShellId : ShellPropIds;
                                  mortar_dot_targetPos : float3;
                                  gun_dot_owner : ecs::EntityId;
                                  gun : IGunHolder;
                                  var trajectory_dot_enabled : bool&;
                                  var trajectory_dot_start : float3&;
                                  var trajectory_dot_vel : float3&)
  if !evt.isForReal || int(gun_dot_curShellId.shellId) < 0
    return
  trajectory_dot_enabled = false
  ecs::query(gun_dot_owner) <| $ [es (REQUIRE=hero)] (human_weap_dot_mortarMode : bool)
    if !human_weap_dot_mortarMode
      return
    trajectory_dot_enabled = true
    let speed = get_shell_speed(gun_dot_curShellId)
    trajectory_dot_start = get_shoot_pos(gun, evt.gloc)
    if calculate_arc_high_start_dir(trajectory_dot_start, mortar_dot_targetPos, speed, trajectory_dot_vel)
      trajectory_dot_vel *= speed

[es (tag=render, REQUIRE=mortar)]
def disable_trajectory_on_mortar_detach(evt : CmdWeapAttach; var trajectory_dot_enabled : bool&)
  if !evt.isAttached
    trajectory_dot_enabled = false
