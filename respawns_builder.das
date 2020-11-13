require enlisted.game.es.fortifications_build_common
require game.utils.team
require game.es.events
require ecs.common
require math.base
require ecs
require app

[es (on_event=EventEntityCreated, tag=server, REQUIRE=team_dot_members)]
def building_respawn_update_team_es(evt: Event; eid: EntityId)
  addSubTemplate(eid, "respawn_creators_team")

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server, before=(respawn_bases_check_group_es, respawn_bases_selector_group_es), REQUIRE=autoSetRespawnGroup)]
def building_respawn_create_es(evt: Event;
                               team: int;
                               var respawnBaseGroup: int&)
  find_query() <| $ [es] (team_dot_id: int; var respawnCreatorId: int&)
    if team_dot_id == team
      respawnBaseGroup = respawnCreatorId
      respawnCreatorId++
      return true
    return false

[es (tag=server, after=respawn_destroyer_on_spawns_change)]
def building_respawn_disabler_by_enemy(info: UpdateStageInfoAct;
                                       team: int;
                                       disableEnemyRadius: float;
                                       nextSpawnActivateAtTime: float;
                                       enemyCheckInterval: float;
                                       transform: float3x4;
                                       isCapZonesOrRespawnsNear: bool;
                                       var isEnemyAtRespawn: bool&;
                                       var active: bool&;
                                       var nextEnemyCheckAtTime: float&)
  if nextEnemyCheckAtTime > info.curTime || isCapZonesOrRespawnsNear
    return
  let respawnTeam = team
  isEnemyAtRespawn = false
  let respawnPos = transform[3]
  find_query() <| $ [es (REQUIRE=human)] (team: int; isAlive: bool; transform: float3x4)
    if !isAlive || team == TEAM_UNASSIGNED || is_teams_friendly(respawnTeam, team)
      return false
    if length_sq(transform[3] - respawnPos) < square(disableEnemyRadius)
      isEnemyAtRespawn = true
      return true
    return false
  active = nextSpawnActivateAtTime <= 0.0 && !isEnemyAtRespawn
  nextEnemyCheckAtTime = info.curTime + enemyCheckInterval

def update_active_for_respawn_by_distance_restrictions()
  query() <| $ [es] (eid: EntityId;
                     disableCapturePointsRadius: float;
                     disableRespawnPointsRadius: float;
                     transform: float3x4;
                     team: int;
                     nextSpawnActivateAtTime: float;
                     isEnemyAtRespawn: bool;
                     var isCapZonesOrRespawnsNear: bool&;
                     var active: bool&)
    if isEnemyAtRespawn || nextSpawnActivateAtTime > 0.0
      return
    isCapZonesOrRespawnsNear = (!is_distance_to_capture_points_valid(transform[3], disableCapturePointsRadius) ||
                                !!find_respawn_eid_for_team_in_radius(transform[3], disableRespawnPointsRadius, eid, team))
    active = !isCapZonesOrRespawnsNear

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=active, tag=server, REQUIRE=(capzone, active))]
def respawn_disabler_capture_zone_check(evt: Event)
  update_active_for_respawn_by_distance_restrictions()

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=active, tag=server, after=building_respawn_disabler_by_enemy, REQUIRE=(respbase, active))]
def respawn_disabler_respawn_base_check(evt: Event)
  update_active_for_respawn_by_distance_restrictions()

[es (on_event=(EventEntityCreated), tag=server)]
def respawn_counter_after_spawn(evt: Event;
                                squad_dot_respawnBaseEid: EntityId)
  query(squad_dot_respawnBaseEid) <| $ [es] (var respawnsBeforeDestroy: int&)
    respawnsBeforeDestroy--

[es (tag=server, track=respawnsBeforeDestroy)]
def respawn_destroyer_on_spawns_change(evt: Event;
                                       eid: EntityId;
                                       respawnCooldown : float;
                                       respawnsBeforeDestroy: int;
                                       var nextSpawnActivateAtTime: float&;
                                       var active: bool&)
  active = false
  nextSpawnActivateAtTime = get_sync_time() + respawnCooldown
  if respawnsBeforeDestroy <= 0
    destroyEntity(eid)
    return

[es (tag=server, after=respawnsBeforeDestroy)]
def respawn_activate_after_cooldown_es(info: UpdateStageInfoAct;
                                       var nextSpawnActivateAtTime: float&;
                                       var active: bool&)
  if nextSpawnActivateAtTime <= 0.0 || nextSpawnActivateAtTime > info.curTime
    return
  active = true
  nextSpawnActivateAtTime = -1.0