require ecs
require app
require math
require math.base
require game.utils.team
require DagorSystem
require walkerai
require EnlistedWalkerai
require DagorMath
require Dacoll
require game.es.events
require game.es.stat_bq_common
require game.es.squad_common
require enlisted.game.es.enlisted_events

def calc_enemy_score(leaderTeam; walker_agent)
  var enemyScore = 0.f
  ecs::query() <| $[es](ai_target: Target;
                        team: int;
                        isAlive: bool)
    if !isAlive
      return

    let maxEnemyDist = 60.f;
    let enemyCanSeeScore = 200.f;

    if is_teams_friendly(leaderTeam, team)
      return

    var dir = get_walker_agent_shoot_from_pos(walker_agent, 2) - ai_target.targetPos
    var dist = length(dir)
    if dist > maxEnemyDist
      return
    dir *= safeinv(dist)
    var norm : float3
    if !traceray_normalized(ai_target.targetPos, dir, dist, norm) // it can see us
      enemyScore += enemyCanSeeScore * (1.f - dist / maxEnemyDist)
  return enemyScore

def find_best_leader(squad_eid): EntityId
  var leaderPos = float3()
  var leaderDir = float3()
  var leaderTeam = TEAM_UNASSIGNED
  var isValidLeader = false
  var isTeamValid = false
  ecs::query(get_squad_leader(squad_eid)) <| $[es](transform: float3x4; team: int)
    isValidLeader = true
    isTeamValid = true
    leaderTeam = team
    leaderDir = transform[0]
    leaderPos = transform[3]

  var minScore = FLT_MAX
  var minDownedScore = FLT_MAX
  var bestEntity = INVALID_ENTITY_ID
  var bestDowned = INVALID_ENTITY_ID

  let curTime = get_sync_time()
  ecs::query() <| $[es (REQUIRE=squad_member)](eid: ecs::EntityId;
                                               walker_agent: EntityAgent;
                                               team: int;
                                               isDowned: bool;
                                               squad_member_dot_squad: EntityId;
                                               isAlive: bool)
    if !isAlive || squad_eid != squad_member_dot_squad
      return
    if !isTeamValid
      leaderTeam = team
      isTeamValid = true
    if leaderTeam != team
      logerr("Squad members have different teams")
      return

    let hitScore = cvt(curTime - walker_agent.lastHitTime, 1.f, 5.f, 100.f, 0.f)
    let distScore = isValidLeader ? length(leaderPos - walker_agent.pos) : 0.f
    let dirScore = isValidLeader ? cvt(dot(walker_agent.shootDir, leaderDir), 1.f, -1.f, 0.f, 10.f) : 0.f
    let enemyScore = calc_enemy_score(leaderTeam, walker_agent)

    let totalScore = hitScore + distScore + dirScore + enemyScore
    if !isDowned
      if totalScore < minScore
        minScore = totalScore
        bestEntity = eid
    elif totalScore < minDownedScore
      minDownedScore = totalScore
      bestDowned = eid

  return bestEntity != INVALID_ENTITY_ID ? bestEntity : bestDowned

[es (tag=server)]
def respawner_es(info: UpdateStageInfoAct;
                 eid: EntityId;
                 isAlive: bool;
                 var respawner_dot_respStartTime: float &;
                 var respawner_dot_enabled: bool&;
                 var respawner_dot_respEndTime: float&;
                 var respawner_dot_canRespawnTime: float&;
                 var respawner_dot_respToBot: bool&;
                 var respawner_dot_spectatorEnabled: bool&;
                 var respawner_dot_chosenRespawn: EntityId&;
                 respawner_dot_respTime: float;
                 respawner_dot_respBotTime: float;
                 respawner_dot_respRequested: bool;
                 respawner_dot_respRequestedSquadId: int = 0;
                 respawner_dot_respRequestedMemberId: int = 0;
                 team: int = TEAM_UNASSIGNED;
                 respawner_dot_selectNextEntityTime: float = 2.f;
                 respawner_dot_invisibilityTime: float = 1.f;
                 respawner_dot_invulnerabilityTime: float = 3.;
                 respawner_dot_respBotTimeout: float = 5.f;
                 respawner_dot_respTimeout: float = 15.f;
                 respawner_dot_allowForceRespawn: bool = true;
                 respawner_dot_allowBotForceRespawn: bool = true;
                 respawner_dot_isFirstSpawn: bool = false;
                 respawner_dot_respawnGroupId: int = -1;
                 squad_member_dot_squad: EntityId = INVALID_ENTITY_ID)
  if isAlive || !respawner_dot_enabled
    return

  if respawner_dot_respStartTime < 0.f
    respawner_dot_respStartTime = info.curTime
    respawner_dot_respEndTime = -1.f
    respawner_dot_canRespawnTime = -1.f

  respawner_dot_spectatorEnabled = false
  if info.curTime < respawner_dot_respStartTime + respawner_dot_selectNextEntityTime
    return

  let respToBot = squad_member_dot_squad != INVALID_ENTITY_ID && get_num_alive_squad_members(squad_member_dot_squad) > 0
  respawner_dot_respToBot = respToBot
  let playerEid = get_Eid(eid, "possessedByPlr") ?? INVALID_ENTITY_ID

  if !respToBot
    let teamEid = get_team_eid(team)

    if (get_bool(teamEid, "team.shouldReduceBotsCount") ?? false) && has(playerEid, "playerIsBot")
      set(teamEid, "team.shouldReduceBotsCount", false)
      print("respawner[{eid}, {getEntityTemplateName(eid)}]: Kick bot player {playerEid}")
      destroyEntity(playerEid)
      return

    let squadCanSpawn = get_bool(playerEid, "squads.squadsCanSpawn") ?? true
    let teamCanSpawn = get_bool(teamEid, "team.squadsCanSpawn") ?? true
    if !squadCanSpawn || !teamCanSpawn
      respawner_dot_respEndTime = -1.f //to hide respawn screen
      respawner_dot_canRespawnTime = -1.f
      respawner_dot_spectatorEnabled = true
      print("respawner[{eid}, {getEntityTemplateName(eid)}]: No respawns left. Enable spectator.")
      return

  let isPlayerSquadOwner = playerEid != INVALID_ENTITY_ID && playerEid == (get_Eid(squad_member_dot_squad, "squad.ownerPlayer") ?? INVALID_ENTITY_ID)

  if respawner_dot_chosenRespawn == INVALID_ENTITY_ID && isPlayerSquadOwner
    respawner_dot_chosenRespawn = find_best_leader(squad_member_dot_squad)

  var forceRespTime = respToBot ? respawner_dot_respBotTimeout : respawner_dot_respTimeout
  var allowRespTime = respToBot ? respawner_dot_respBotTime : respawner_dot_respTime

  if !respToBot
    ecs::query(playerEid) <| $[es](squads_dot_respawnPenaltyTime: float)
      allowRespTime += squads_dot_respawnPenaltyTime
      forceRespTime += squads_dot_respawnPenaltyTime

  respawner_dot_canRespawnTime = respawner_dot_respStartTime + allowRespTime

  if respawner_dot_respRequested
    respawner_dot_respEndTime = respawner_dot_canRespawnTime
  else
    let allowForceRespawn = respToBot ? respawner_dot_allowBotForceRespawn : respawner_dot_allowForceRespawn
    respawner_dot_respEndTime = allowForceRespawn ? respawner_dot_respStartTime + forceRespTime : -1.f

  if respawner_dot_respEndTime >= 0.f && info.curTime > respawner_dot_respEndTime // force respawn
    if respawner_dot_isFirstSpawn || isPlayerSquadOwner || has(eid, "respawner")
      var newEid = respawner_dot_chosenRespawn
      if !doesEntityExist(newEid) && squad_member_dot_squad != INVALID_ENTITY_ID
        newEid = find_best_leader(squad_member_dot_squad)
      print("respawner_es {eid}: force spawn entity {newEid} for player {playerEid} (squad {squad_member_dot_squad}), respEndTime {respawner_dot_respEndTime}")
      if playerEid == INVALID_ENTITY_ID || !(get_bool(playerEid, "disconnected") ?? true) // refuse to spawn entity for disconnected players
        if newEid != INVALID_ENTITY_ID
          print("respawner[{eid}, {getEntityTemplateName(eid)}]: Respawn to the next soldier in squad: {newEid}")
          set(squad_member_dot_squad, "squad.leader", newEid)
          sendEvent(playerEid, [[CmdPossessEntity possessedEid=newEid]])
          ecs::query(newEid) <| $[es](var beh_tree_dot_enabled: bool&;
                                      var human_weap_dot_infiniteAmmoHolders: bool&;
                                      var ai_target_dot_invisibleTimeTo: float&;
                                      var hitpoints_dot_invulnerableTimeTo: float&;
                                      var hitpoints_dot_bulletInvulnerableCurDamageMult: float&;
                                      hitpoints_dot_bulletInvulnerableStartDamage: float = 1.f)
            beh_tree_dot_enabled = false
            human_weap_dot_infiniteAmmoHolders = false
            ai_target_dot_invisibleTimeTo = info.curTime + respawner_dot_invisibilityTime
            hitpoints_dot_invulnerableTimeTo = info.curTime + respawner_dot_invulnerabilityTime
            hitpoints_dot_bulletInvulnerableCurDamageMult = hitpoints_dot_bulletInvulnerableStartDamage
        else
          let squadId = respawner_dot_respRequestedSquadId
          let memberId = respawner_dot_respRequestedMemberId
          let respawnGroupId = respawner_dot_respawnGroupId
          print("respawner[{eid}, {getEntityTemplateName(eid)}]: Respawn a new squad: {squadId}, {memberId}, {respawnGroupId}")
          sendEvent(playerEid, [[CmdSpawnSquad team=team, possessed=eid, squadId=squadId, memberId=memberId, respawnGroupId=respawnGroupId]])
      else
        logwarn("respawner_es {eid}: player {playerEid} is disconnected")
    else
      logwarn("respawner_es {eid}: is not leader of squad {squad_member_dot_squad} (actual squad.leader {get_squad_leader(squad_member_dot_squad)})")

    respawner_dot_enabled = false
    respawner_dot_respStartTime = -1.f
    respawner_dot_respEndTime = -1.f
    respawner_dot_canRespawnTime = -1.f

[es (tag=server, on_event=EventEntityDestroyed)]
def respawners_destroyed_check(evt : Event; possessedByPlr : EntityId; squad_member_dot_squad : EntityId)
  if !possessedByPlr || get_num_alive_squad_members(squad_member_dot_squad) > 0
    return
  let respawnerExists = find_query() <| $[es] (respawner_dot_player : EntityId)
    return possessedByPlr == respawner_dot_player
  if respawnerExists
    return
  send_schemeless_event(possessedByPlr, typeinfo(undecorated_typename type<CmdCreateRespawner>))

[es (no_order)]
def respawner_reset_chosen_respawn(info: UpdateStageInfoAct; var respawner_dot_chosenRespawn: EntityId&)
  var found = false
  query(respawner_dot_chosenRespawn) <| $[es](isAlive: bool)
    found = true
    if !isAlive
      respawner_dot_chosenRespawn = INVALID_ENTITY_ID
  if !found
    respawner_dot_chosenRespawn