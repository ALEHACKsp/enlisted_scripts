require ecs
require game.es.events
require DagorMath
require DagorSystem
require ecs.common
require app

struct BattleAreaPoint
  id : string
  nextId : string
  pos : float3
  visited : bool

def find_next_point_index(nextId, points)
  return find_index_if(points) <| $ (p) : bool { return p.id == nextId; }

def poly_battle_area_create_on_load_es_impl(eid : EntityId; var battleAreaPoints: ecs::Point2List; battleAreaId: string; levelLoaded : bool)
  var points : array<BattleAreaPoint>
  query() <| $ [es](battle_area_polygon_point_dot_nextId: string; battle_area_polygon_point_dot_id: string; battle_area_polygon_point_dot_forBattleAreaId: string; transform: float3x4)
    if battle_area_polygon_point_dot_forBattleAreaId == battleAreaId
      push(points, [[BattleAreaPoint id=battle_area_polygon_point_dot_id, nextId=battle_area_polygon_point_dot_nextId, pos=transform[3]]])

  let pointsCount = length(points)
  if (pointsCount < 3)
    logerr("Battle area must have at least 3 points, battleAreaId {battleAreaId}")
  if levelLoaded
    var pointCountShouldMatch = false
    find_query() <| $ [es] (level_dot_fixedBattleAreas : bool; level_dot_navAreas: EidList)
      if level_dot_fixedBattleAreas
        for navAreaEid in level_dot_navAreas
          if navAreaEid == eid
            pointCountShouldMatch = true;
            return true;
      return false;
    if pointCountShouldMatch && (length(battleAreaPoints) != pointsCount)
      logerr("This level is using fixed human battle areas, point of {battleAreaId} should be created before level entity in {get_current_scene()}")
  resize(battleAreaPoints, pointsCount)
  var curPointId = 0
  try
    for i in range(0, pointsCount)
      assert(!points[curPointId].visited || curPointId == 0)
      points[curPointId].visited = true
      battleAreaPoints[i] = points[curPointId].pos.xz
      curPointId = find_next_point_index(points[curPointId].nextId, points)
  recover
    logerr("Segments don't form a closed polygonal chain or loop has been detected in the battle area's polygon {battleAreaId}")

[es (tag=server, on_event=EventLevelLoaded, REQUIRE=battle_area)]
def poly_battle_area_create_on_load_es(evt: Event; eid : EntityId; var battleAreaPoints: ecs::Point2List; battleAreaId: string)
  poly_battle_area_create_on_load_es_impl(eid, battleAreaPoints, battleAreaId, true)

[es (tag=server, on_event=CmdInitPolyBattleAreas, REQUIRE=battle_area)]
def poly_battle_area_create_on_reinit_es(evt: Event; eid : EntityId; var battleAreaPoints: ecs::Point2List; battleAreaId: string)
  poly_battle_area_create_on_load_es_impl(eid, battleAreaPoints, battleAreaId, false)
