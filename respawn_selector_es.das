require ecs
require game.es.events
require DagorMath
require DagorSystem
require player
require game.utils.team
require math
require app

struct Group
  count: int = 0
  posSum: float3 = float3()
  canBeAutoSelected: bool = true

typedef
  RespawnGroupMap = table<int; Group>

def create_spawn_icons(var spawnTable; iconType, forTeam)
  for k, v in keys(spawnTable), values(spawnTable)
    let iconTemplate = spawnTable[k].canBeAutoSelected ? "respawn_point_selector+auto_respawn_point_selector" : "respawn_point_selector"
    createEntitySync(iconTemplate) <| $ (var init:ComponentsInitializer)
      var tm : float3x4
      identity(tm)
      tm[3] = spawnTable[k].posSum / float(spawnTable[k].count)
      set(init, "transform", tm)
      set(init, "selectedGroup", k)
      set(init, "respawnIconType", iconType)
      set(init, "team", forTeam)

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear))]
def respawn_bases_check_group_es(evt : Event; respawnBaseGroup : int)
  if respawnBaseGroup == -1
    logerr("respawn base has group (component respawnBaseGroup) but equal -1")

def update_respawn_bases_points(forTeam : int; exclude_eid = INVALID_ENTITY_ID)
  ecs::query() <| $[es (REQUIRE=respawnIconType)](eid: EntityId; team: int)
    if team == forTeam
      destroyEntity(eid)
  var  spawnGroups : table<string; RespawnGroupMap>
  ecs::query() <| $[es (REQUIRE_NOT=aircraftRespbase)](eid: EntityId; team : int; active : bool; respawnBaseGroup : int; transform: float3x4; respawnbaseType : string)
    if eid == exclude_eid || !(is_teams_friendly(forTeam, team) || forTeam == TEAM_UNASSIGNED) || !active
      return
    var curTable & = spawnGroups[respawnbaseType]
    let v = curTable?[respawnBaseGroup] ?? [[Group]]
    let isCustomRespawn = has(eid, "respawnCooldown")
    curTable[respawnBaseGroup] = [[Group count=v.count + 1, posSum=v.posSum + transform[3], canBeAutoSelected = !isCustomRespawn]]
  for k, v in keys(spawnGroups), values(spawnGroups)
    create_spawn_icons(v, k, forTeam)

[es (tag=server, track=active, track=team, on_event=(EventEntityCreated, EventComponentsAppear, EventLevelLoaded), REQUIRE=respawnBaseGroup, REQUIRE=active)]
def respawn_bases_selector_group_es(evt : Event; team : int)
  update_respawn_bases_points(team)

[es (tag=server, on_event=EventEntityDestroyed, REQUIRE=respawnBaseGroup, REQUIRE=active)]
def respawn_bases_destroy_group_es(evt: Event; eid: EntityId; team: int)
  update_respawn_bases_points(team, eid)