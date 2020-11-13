require ecs
require game.es.events
require DagorMath
require DagorConsole
require DagorSystem
require DagorDebug3D

[console_cmd(name="battleAreas.reinit_active_poly_areas")]
def reinit_active_poly_areas()
  ecs::query() <| $[es(REQUIRE=battleAreaPoints)](eid : EntityId; active : bool)
    if active
      sendEvent(eid, [[CmdInitPolyBattleAreas]])

[console_cmd(name="battleAreas.draw_active_poly_areas")]
def draw_active_poly_areas(draw_info : bool = true)
  ecs::query() <| $[es(REQUIRE=battleAreaPoints)](eid: EntityId; active: bool; battleAreaId: string)
    if !draw_info
      removeSubTemplate(eid, "poly_battle_area_draw_debug")
      return
    if active
      var height = 0.f
      query() <| $ [es](battle_area_polygon_point_dot_forBattleAreaId: string; transform: float3x4)
        let pointHeight = transform[3][1]
        if (battle_area_polygon_point_dot_forBattleAreaId == battleAreaId) && (pointHeight > height)
          height = pointHeight
      addSubTemplate(eid, "poly_battle_area_draw_debug") <| $(var init)
        set(init, "battle_area_polygon_point.drawOnHeight", height)
        set(init, "battle_area_polygon_point.drawDebug", draw_info)

def point2_to_point3_height(inPoint, height)
  return float3(inPoint.x, height, inPoint.y)

[es (tag=dev, tag=render, no_order)]
def poly_areas_draw_lines_es(evt: UpdateStageInfoRenderDebug;
                             battleAreaPoints: ecs::Point2List;
                             battle_area_polygon_point_dot_drawDebug: bool;
                             battle_area_polygon_point_dot_drawOnHeight: float;
                             battle_area_polygon_point_dot_additionalHeight: float)
  if (!battle_area_polygon_point_dot_drawDebug || length(battleAreaPoints) == 0)
    return
  let height = battle_area_polygon_point_dot_drawOnHeight + battle_area_polygon_point_dot_additionalHeight
  for i in iter_range(battleAreaPoints)
    var pointStart = point2_to_point3_height(battleAreaPoints[i], height)
    var pointEnd = point2_to_point3_height(battleAreaPoints[(i+1) % length(battleAreaPoints)], height)
    draw_debug_line_buffered(pointStart, pointEnd, E3DCOLOR(0xFFFF0000), 220)


[es (tag=dev, tag=render, no_order)]
def poly_areas_draw_points_es(evt: UpdateStageInfoRenderDebug; battle_area_polygon_point_dot_drawDebug : bool; battleAreaId : string)
  if !battle_area_polygon_point_dot_drawDebug
    return
  query() <| $ [es](battle_area_polygon_point_dot_nextId: string;
                    battle_area_polygon_point_dot_id: string;
                    battle_area_polygon_point_dot_forBattleAreaId: string;
                    transform:float3x4)
    if battle_area_polygon_point_dot_forBattleAreaId == battleAreaId
      add_debug_text_mark(transform[3], "Cur point {battle_area_polygon_point_dot_id}
        next {battle_area_polygon_point_dot_nextId} for {battleAreaId}", -1, 0., E3DCOLOR(0xFFFF0000))

[es (tag=server, on_event=CmdInitPolyBattleAreas, after=poly_battle_area_create_on_load_es, REQUIRE=battle_area_polygon_point_dot_drawDebug)]
def poly_battle_area_check_points_orientation_es(evt: Event; battleAreaPoints: ecs::Point2List; battleAreaId: string)
  var area = 0.f
  let numOfPoints = length(battleAreaPoints)
  for i in range(0, numOfPoints)
    let pointId = (i+1) % numOfPoints
    let point1 = battleAreaPoints[i]
    let point2 = battleAreaPoints[pointId]
    area += (point1.x - point2.x) * (point1.y + point2.y);
  area /= 2.f
  if area < 0.0
    logerr("Points should be counterclockwise. Error in {battleAreaId}")