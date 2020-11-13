require ecs
require player
require game.utils.hero
require dm
require game.es.events
require enlisted.game.es.enlisted_events
require DagorConsole
require DagorMath

[private]
def kill_squad(squad_eid : EntityId)
  ecs::query() <| $ [es] (eid : ecs::EntityId; squad_member_dot_squad : ecs::EntityId)
    if squad_eid == squad_member_dot_squad
      sendEvent(eid, [[CmdKill offender=eid, damageType=uint16(int(DamageType DM_MELEE))]])

[console_cmd(name="squad.suicide")]
def squad_suiside_debug(squad = 0u)
  var squadEid = EntityId(squad)
  if squadEid == INVALID_ENTITY_ID
    let hero = get_controlled_hero()
    squadEid = get_Eid(hero, "squad_member.squad") ?? INVALID_ENTITY_ID
  kill_squad(squadEid)

[console_cmd(name="squad.changeTeam")]
def squad_change_team()
  let playerEid = get_local_player_eid()
  if !playerEid
    visual_log("local player is INVALID")
    return
  let possessed = get_Eid(playerEid, "possessed") ?? INVALID_ENTITY_ID
  let squadEid = get_Eid(possessed, "squad_member.squad") ?? INVALID_ENTITY_ID
  let team = get_int(playerEid, "team") ?? 1
  let newTeam = team == 1 ? 2 : 1

  kill_squad(squadEid)
  broadcastEvent([[EventTeamMemberLeave eid=playerEid, team = team]])
  broadcastEvent([[EventTeamMemberJoined eid=playerEid, team = newTeam]])
  set(playerEid, "team", newTeam)
  sendEvent(playerEid, [[CmdSpawnSquad team=newTeam, possessed=possessed, squadId=0, memberId=0, respawnGroupId=-1]])

[console_cmd(name="squad.spawnMoreSoldiers")]
def squad_spawnMoreSoldiers()
  var offset = float3(0.f, 0.f, 0.f)
  for i in range(0, 5)
    createEntity("usa_base_soldier_01") <| $(var init: ComponentsInitializer)
      var tm: float3x4
      tm[0] = float3(0.999f, 0.000f, 0.048f)
      tm[1] = float3(0.000f, 1.000f, 0.000f)
      tm[2] = float3(-0.048f, 0.000f, 0.999f)
      tm[3] = float3(-139.2f, -3.970f, 217.5f) + offset
      set(init, "transform", tm)
      set(init, "team", 0)
      set(init, "spawn_immunity.timer", 0.f)

      offset += float3(0.f, 0.f, 1.f)