require ecs
require ecs.common
require app
require game.es.events
require game.utils.team
require DaWeaponProps
require EnlistedWeapon
require game.es.sound.sound_events
require soundHash
require math
require math.base

def resupply(turret_control_dot_gunEids : EidList)
  for gunEid in turret_control_dot_gunEids
    query(gunEid) <| $ [es] (gun_dot_maxAmmo : int;
                             var gun_dot_ammo : int&;
                             gun_dot_curShellId: ShellPropIds;
                             gun_dot_shell_prop_ids: GunShellPropIds;
                             gun_dot_shellsAmmo : Array;
                             var gun_dot_ammo_by_shell: IntList&)
      gun_dot_ammo = gun_dot_maxAmmo
      let minCount = min(min(length(gun_dot_shell_prop_ids), length(gun_dot_ammo_by_shell)), length(gun_dot_shellsAmmo))
      for shellType in range(0, minCount)
        gun_dot_ammo_by_shell[shellType] = get_int(gun_dot_shellsAmmo[shellType]) ?? 0
        if int(gun_dot_curShellId.shellId) == int(gun_dot_shell_prop_ids[shellType].shellId)
          gun_dot_ammo = gun_dot_ammo_by_shell[shellType]

def need_resupply(turret_control_dot_gunEids : EidList)
  var needResupply = false
  for gunEid in turret_control_dot_gunEids
    query(gunEid) <| $ [es] (gun_dot_shell_prop_ids: GunShellPropIds;
                             gun_dot_shellsAmmo : Array;
                             gun_dot_ammo_by_shell: IntList)
      let minCount = min(min(length(gun_dot_shell_prop_ids), length(gun_dot_ammo_by_shell)), length(gun_dot_shellsAmmo))
      for shellType in range(0, minCount)
        if gun_dot_ammo_by_shell[shellType] < get_int(gun_dot_shellsAmmo[shellType]) ?? 0
          needResupply = true
          return
  return needResupply

def play_resupply_sound(eid : ecs::EntityId)
  sendEvent(eid, [[CmdPlayNetSound hash=sound_hash("resupplyStart"), pos=float3(), param=0., interval=0., time=get_sync_time()]])

def is_applied_for_zone(zone_pos: float3; zone_radius_sq : float; zone_team : int; visitor_pos : float3; visitor_team : int)
  return (zone_team == TEAM_UNASSIGNED || zone_team==visitor_team) && distance_sq(zone_pos, visitor_pos) < zone_radius_sq

def zone_timer(at_time: float; resupply_zone_dot_updateInterval : float; var resupply_zone_dot_nextUpdateAtTime : float&)
  if at_time < resupply_zone_dot_nextUpdateAtTime
    return false
  resupply_zone_dot_nextUpdateAtTime = at_time + resupply_zone_dot_updateInterval
  return true

def apply_zone(at_time : float;
               zone_pos : float3;
               zone_radius_sq : float;
               zone_team : int;
               resupply_zone_dot_cooldown : float;
               visitor_eid : EntityId;
               visitor_pos : float3;
               visitor_team : int;
               turret_control_dot_gunEids : EidList;
               var resupplyAtTime : float&;
               var resupplyStarted : bool&)
  if !is_applied_for_zone(zone_pos, zone_radius_sq, zone_team, visitor_pos, visitor_team)
    return
  if resupplyStarted
    resupply(turret_control_dot_gunEids)
    resupplyAtTime = at_time + resupply_zone_dot_cooldown
    resupplyStarted = false
  elif at_time > resupplyAtTime && need_resupply(turret_control_dot_gunEids)
    play_resupply_sound(visitor_eid)
    resupplyStarted = true


[es (no_order, tag=server, REQUIRE=planeResupply)]
def resupply_in_air_zone_timer(info : UpdateStageInfoAct;
                               active : bool;
                               transform : float3x4;
                               resupply_zone_dot_team : int;
                               sphere_zone_dot_radius : float;
                               resupply_zone_dot_cooldown : float;
                               resupply_zone_dot_updateInterval : float;
                               var resupply_zone_dot_nextUpdateAtTime : float&)
  if !active || !zone_timer(info.curTime, resupply_zone_dot_updateInterval, resupply_zone_dot_nextUpdateAtTime)
    return
  let zonePos = transform[3]
  let zoneRadiusSq = square(sphere_zone_dot_radius)
  query() <| $ [es (REQUIRE=airplane)] (eid : EntityId; team : int; transform : float3x4; turret_control_dot_gunEids : EidList; var resupplyAtTime : float&; var resupplyStarted : bool&)
    apply_zone(info.curTime, zonePos, zoneRadiusSq, resupply_zone_dot_team, resupply_zone_dot_cooldown, eid, transform[3], team, turret_control_dot_gunEids, resupplyAtTime, resupplyStarted)

[es (no_order, tag=server, REQUIRE=groundVehicleResupply)]
def resupply_on_ground_zone_timer(info : UpdateStageInfoAct;
                                  active : bool;
                                  transform : float3x4;
                                  resupply_zone_dot_team : int;
                                  sphere_zone_dot_radius : float;
                                  resupply_zone_dot_cooldown : float;
                                  resupply_zone_dot_updateInterval : float;
                                  var resupply_zone_dot_nextUpdateAtTime : float&)
  if !active || !zone_timer(info.curTime, resupply_zone_dot_updateInterval, resupply_zone_dot_nextUpdateAtTime)
    return
  let zonePos = transform[3]
  let zoneRadiusSq = square(sphere_zone_dot_radius)
  query() <| $ [es (REQUIRE=vehicle, REQUIRE_NOT=airplane)] (eid : EntityId; team : int; transform : float3x4; turret_control_dot_gunEids : EidList; var resupplyAtTime : float&; var resupplyStarted : bool&)
    apply_zone(info.curTime, zonePos, zoneRadiusSq, resupply_zone_dot_team, resupply_zone_dot_cooldown, eid, transform[3], team, turret_control_dot_gunEids, resupplyAtTime, resupplyStarted)