require ecs
require player
require math
require game.es.events
require game.es.vehicle.vehicle_events
require DagorConsole
require DagorMath
require Dacoll

[console_cmd(name="aircraft.spawnInAir")]
def aircraft_debug()
  var playerEid = get_local_player_eid()
  if !playerEid
    find_query() <| $[es (REQUIRE=player)](eid: EntityId) { playerEid = eid; return true; }

  query() <| $[es (REQUIRE=hero)](eid: EntityId; transform: float3x4; squad_member_dot_squad: EntityId)
    let finalizeCreation <- @ <| (vehicleEid: EntityId)
      sendEventImmediate(playerEid, [[CmdUseVehiceOnSpawn possessed=eid, squad=squad_member_dot_squad, vehicle=vehicleEid, seatOrderNo=0]])

    createEntity("il_2_1941+plane_spawn_in_air", finalizeCreation) <| $(var init: ComponentsInitializer)
      set(init, "startVelDir", float3(1.f, 0.f, 0.f))
      set(init, "startRelativeSpeed", 1.f)

      var tm = float3x4()
      identity(tm)
      tm[3] = transform[3] + float3(0.f, 1000.f, 0.f)
      set(init, "transform", tm)

[console_cmd(name="aircraft.dropBomb")]
def aircraft_dropBomb()
  var playerEid = get_local_player_eid()
  if !playerEid
    find_query() <| $[es (REQUIRE=player)](eid: EntityId) { playerEid = eid; return true; }

  let tmpl = "plane_debug_drop_bomb"
  ecs::createTemplate(tmpl, "", "", "", false) <| $(var cmp : ecs::ComponentsMap)
    set(cmp, "plane_debug.dropBomb", true)

  query() <| $[es (REQUIRE=hero)](human_dot_aimTm: float3x4)
    createEntity("il_2_1941+plane_spawn_in_air+{tmpl}") <| $(var init: ComponentsInitializer)
      set(init, "startVelDir", float3(1.f, 0.f, 0.f))
      set(init, "startRelativeSpeed", 1.f)

      var len = 100.f
      var norm = float3()
      traceray_normalized(human_dot_aimTm[3], human_dot_aimTm[0], len, norm)

      var tm = float3x4()
      identity(tm)
      tm[0] = float3(0.f, -1.f, 0.f)
      tm[1] = float3(1.f, 0.f, 0.f)
      tm[2] = float3(0.f, 0.f, 1.f)
      tm[3] = (human_dot_aimTm[3] + human_dot_aimTm[0] * len) + float3(0.f, 200.f, 0.f)
      set(init, "transform", tm)

[es (REQUIRE=plane_debug_dot_dropBomb, after=turret_weap_reset_shoot)]
def aircraft_shoot_all(evt: CmdPostPhysUpdate; eid: EntityId; var turret_aim_dot_shootFlag: BoolList)
  turret_aim_dot_shootFlag[4] = true
  destroyEntity(eid)

[console_cmd(name="spawn.plane_side")]
def debug_spawn_plane_side(dist : float = 500.0; side_dist: float = 300.0; relative_height : float = 0.0)
  query() <| $ [es] (possessedByPlr : EntityId; transform : float3x4)
    if !possessedByPlr
      return

    let up = float3(0,1,0)
    let pos = transform[3]
    let dir = transform[0]
    let side = transform[2]
    createEntity("bf_109g_6+plane_spawn_in_air") <| $ (var init: ComponentsInitializer)
      var tm: float3x4
      identity(tm)
      tm[3] = pos + dir * dist - side * side_dist + up * relative_height
      tm[0] = transform[2]
      tm[1] = transform[1]
      tm[2] = transform[0]
      set(init, "transform", tm)

[console_cmd(name="spawn.plane")]
def debug_spawn_plane(dist : float = 300.0; same_course = true; relative_height : float = 0.0)
  query() <| $ [es] (possessedByPlr : EntityId; transform : float3x4)
    if !possessedByPlr
      return

    let up = float3(0,1,0)
    let pos = transform[3]
    let dir = transform[0]
    let side = transform[2]
    createEntity("bf_109g_6+plane_spawn_in_air") <| $ (var init: ComponentsInitializer)
      var tm: float3x4
      identity(tm)
      tm[3] = pos + dir * dist + up * relative_height
      tm[0] = transform[0] * (same_course ? 1.0 : -1.0)
      tm[1] = transform[1]
      tm[2] = transform[2]
      set(init, "transform", tm)
      set(init, "startRelativeSpeed", 0.3)