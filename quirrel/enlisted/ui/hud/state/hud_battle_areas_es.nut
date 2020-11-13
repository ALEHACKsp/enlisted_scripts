local { TEAM_UNASSIGNED } = require("team")
local { localPlayerTeam } = require("ui/hud/state/local_player.nut")
local { watchedHeroEid } = require("ui/hud/state/hero_state_es.nut")
local { logerr, debug } = require("dagor.debug")
local { is_point_in_zone } = require("ecs.utils")
local { fabs } = require("math")
local { Point2, Point3 } = require("dagor.math")

local activeBattleAreasState = Watched(null)
local battleAreasPolygon = Watched(null)


local function checkInSquareZone(battleAreaZones, checkingPoint){ //lines are sorted clockwise
  foreach(zone in battleAreaZones){
    local D1 = (zone.line1.end.x - zone.line1.start.x) * (checkingPoint.y - zone.line1.start.y) -
               (zone.line1.end.y - zone.line1.start.y) * (checkingPoint.x - zone.line1.start.x)
    local D2 = (zone.line2.end.x - zone.line2.start.x) * (checkingPoint.y - zone.line2.start.y) -
               (zone.line2.end.y - zone.line2.start.y) * (checkingPoint.x - zone.line2.start.x)
    local D3 = (zone.line3.end.x - zone.line3.start.x) * (checkingPoint.y - zone.line3.start.y) -
               (zone.line3.end.y - zone.line3.start.y) * (checkingPoint.x - zone.line3.start.x)
    local D4 = (zone.line4.end.x - zone.line4.start.x) * (checkingPoint.y - zone.line4.start.y) -
               (zone.line4.end.y - zone.line4.start.y) * (checkingPoint.x - zone.line4.start.x)
    local eps = 0.05
    if (D1 > eps && D2 > eps && D3 > eps && D4 > eps)
      return true
  }
  return false
}

local function checkInPolyZone(polyBattleAreaZones, checkingPoint, excludeEids){
  local checkingPoint3 = Point3(checkingPoint.x,0,checkingPoint.y)
  foreach(zone in polyBattleAreaZones){
    local skipZone = false
    foreach (excludeEid in excludeEids){
      skipZone = zone == excludeEid
      if (skipZone)
        break
    }
    if (!skipZone && is_point_in_zone(checkingPoint3, zone, 1.))
      return true
  }
  return false
}

local function intersection(start1, end1, start2, end2){
  local  out_intersection = Point2()
  local dir1 = end1 - start1
  local dir2 = end2 - start2

  local a1 = -dir1.y
  local b1 = dir1.x
  local d1 = -(a1*start1.x + b1*start1.y)

  local a2 = -dir2.y
  local b2 = dir2.x
  local d2 = -(a2*start2.x + b2*start2.y)

  local seg1_line2_start = a2*start1.x + b2*start1.y + d2
  local seg1_line2_end = a2*end1.x + b2*end1.y + d2
  local seg2_line1_start = a1*start2.x + b1*start2.y + d1
  local seg2_line1_end = a1*end2.x + b1*end2.y + d1

  if (seg1_line2_start * seg1_line2_end >= 0 || seg2_line1_start * seg2_line1_end >= 0)
    return false

  local u = seg1_line2_start / (seg1_line2_start - seg1_line2_end)
  out_intersection =  start1 + Point2(u*dir1.x, u*dir1.y)
  return out_intersection
}

local mkFilterByTeam = @(team_id)
  @"or(eq(opt(battle_area.team,{1}),{0}),eq(opt(battle_area.team,{1}),{1}))".subst(team_id, TEAM_UNASSIGNED)

local battleAreaFilterStr = "and(and(eq(active,true),eq(battle_area.isVisible,true)),{0})"

local boxBattleAreaQuery = ::ecs.SqQuery("boxBattleAreaQuery", {
  comps_ro = [
    ["transform", ::ecs.TYPE_MATRIX],
    ["active", ::ecs.TYPE_BOOL],
    ["battle_area.isVisible", ::ecs.TYPE_BOOL],
    ["battle_area.team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
  ],
  comps_rq = ["battle_area", "box_zone"],
  comps_no = ["hideOnMinimap"]
})

local function floats_equal(a, b, eps = 0.01) {
  return fabs(a - b) < eps
}

local polyBattleAreaQuery = ::ecs.SqQuery("polyBattleAreaQuery", {
  comps_ro = [
    ["battleAreaPoints", ::ecs.TYPE_POINT2_LIST],
    ["active", ::ecs.TYPE_BOOL],
    ["battle_area.isVisible", ::ecs.TYPE_BOOL],
    ["battle_area.team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
  ],
  comps_rq = ["battle_area"],
  comps_no = ["hideOnMinimap"]
})

local mkSegment = @(a, b, eids = []) {start = Point2(a.x, a.y), end = Point2(b.x, b.y), excludeCheckEids = eids}
local isPointsEqual = @(a,b) (a.x == b.x) && (a.y == b.y)
local isSegmentsEqual = @(a,b) isPointsEqual(a.start, b.start) && isPointsEqual(a.end, b.end)

local function is_on_segment(p, seg) {
  if (isPointsEqual(p, seg.start) || isPointsEqual(p, seg.end))
    return false
  local startSegment = p - seg.start
  local endSegment = seg.end - p
  local segmentDistanceThroughPoint = startSegment.length() + endSegment.length()
  local segmentVec = seg.start - seg.end
  local segmentLength = segmentVec.length()
  return floats_equal(segmentDistanceThroughPoint,segmentLength, 1e-4)
}

local function splitSegment(segments, curSegmentId, dividingPoint){
  if (isPointsEqual(dividingPoint, segments[curSegmentId].start) ||
      isPointsEqual(dividingPoint, segments[curSegmentId].end))
    return
  local curSegExcludeEids = segments[curSegmentId]?.excludeCheckEids ?? []
  local newSegment = mkSegment(dividingPoint, segments[curSegmentId].end, curSegExcludeEids)
  segments[curSegmentId] = mkSegment(segments[curSegmentId].start, dividingPoint, curSegExcludeEids)
  segments.append(newSegment)
}

local function findNextSegment(segmentToExtend, segments) {
  foreach (s in segments)
    if (s != segmentToExtend.seg && floats_equal(s.start.x, segmentToExtend.linkTo.x) && floats_equal(s.start.y, segmentToExtend.linkTo.y))
      return {seg = s, linkTo = s.end}
  foreach (s in segments)
    if (s != segmentToExtend.seg && floats_equal(s.end.x, segmentToExtend.linkTo.x) && floats_equal(s.end.y, segmentToExtend.linkTo.y))
      return {seg = s, linkTo = s.start}
  logerr("Can't build battleAreas ui polygon, see debug for more info")
  debug($"Battle area segments = {segments}")
  return null
}

const BIGNUM = 10000.0
local function buildPolygon(segments) {
  if (segments.len() == 0)
    return null
  local polygon = []
  local currentSegment = {seg = segments[0], linkTo = segments[0].end}
  local minPoint = Point2(BIGNUM, BIGNUM)
  local maxPoint = Point2(-BIGNUM, -BIGNUM)
  for (local i = 0; i < segments.len(); i++) {
    local p = currentSegment.linkTo
    polygon.append(p)
    currentSegment = findNextSegment(currentSegment, segments)
    if (currentSegment == null)
      return null
    maxPoint.x = max(maxPoint.x, p.x)
    maxPoint.y = max(maxPoint.y, p.y)
    minPoint.x = min(minPoint.x, p.x)
    minPoint.y = min(minPoint.y, p.y)
  }

  local radius = 0.0
  if (minPoint.x != BIGNUM && minPoint.y != BIGNUM && maxPoint.x != -BIGNUM && maxPoint.y != -BIGNUM)
    radius = 0.5 * max(maxPoint.x - minPoint.x, maxPoint.y - minPoint.y)

  return { points = polygon, radius = radius }
}

local function splitOverlappingSegments(segments) {
  for(local i = 0; i < segments.len(); i++)
    for(local j = 0; j < segments.len(); j++){
      if (is_on_segment(segments[i].start, segments[j]))
        splitSegment(segments, j, segments[i].start)
      if (is_on_segment(segments[i].end, segments[j]))
        splitSegment(segments, j, segments[i].end)
    }
}

local function clearDuplicates(segments) {
  for(local i = 0; i < segments.len(); i++){
    for(local j = i+1; j < segments.len(); j++) {
      if (segments[j]?.duplicate == true)
        continue
      if (isSegmentsEqual(segments[i],segments[j])) {
        segments[j].duplicate <- true
        if (!segments[j]?.excludeCheckEids)
          segments[j].excludeCheckEids <- []
        if (!segments[i]?.excludeCheckEids)
          continue
        segments[i].excludeCheckEids.extend(segments[j].excludeCheckEids)
      }
    }
  }
  segments = segments.filter(@(v) v?.duplicate != true)
}

local isTagsEqual = @(eid, heroTag) heroTag != null && ::ecs.get_comp_val(eid, heroTag) != null

local function battleAreaHud(evt, eid, comp) {
  local segments = []
  local squareBattleAreaZones = []
  local polyBattleAreaZones = []

  local activeBattleAreas = []
  local filter = battleAreaFilterStr.subst(mkFilterByTeam(localPlayerTeam.value))
  boxBattleAreaQuery.perform(function(eid, comps) { activeBattleAreas.append(eid) }, filter)
  polyBattleAreaQuery.perform(function(eid, comps) { activeBattleAreas.append(eid) }, filter)

  local heroCaprureTag = ::ecs.get_comp_val(watchedHeroEid.value, "zones_visitor.triggerTag")
  activeBattleAreas = activeBattleAreas.filter(@(battleAreaEid) isTagsEqual(battleAreaEid, heroCaprureTag))
  local prevActiveBattleAreas = activeBattleAreasState.value ?? []
  if (prevActiveBattleAreas.len() == activeBattleAreas.len()) {
    local isEqual = true
    foreach (areaEid in activeBattleAreas)
      if (prevActiveBattleAreas.indexof(areaEid) == null) {
        isEqual = false
        break
      }
    if (isEqual)
      return
  }

  activeBattleAreasState.update(activeBattleAreas)

  boxBattleAreaQuery.perform(function(eid, comps){
    if (!isTagsEqual(eid, heroCaprureTag))
      return
    local tm = comps["transform"]
    local diag2 = tm.getcol(0) * 0.5 + tm.getcol(2) * 0.5
    local diag1 = tm.getcol(0) * 0.5 - tm.getcol(2) * 0.5
    local pos = tm.getcol(3)
    local line1 = {start = Point2(pos.x - diag2.x,pos.z - diag2.z),
                   end = Point2(pos.x + diag1.x, pos.z + diag1.z)}
    local line2 = {start = Point2(pos.x + diag1.x,pos.z + diag1.z),
                   end = Point2(pos.x + diag2.x, pos.z + diag2.z)}
    local line3 = {start = Point2(pos.x + diag2.x,pos.z + diag2.z),
                   end = Point2(pos.x - diag1.x, pos.z - diag1.z)}
    local line4 = {start = Point2(pos.x - diag1.x,pos.z - diag1.z),
                   end = Point2(pos.x - diag2.x, pos.z - diag2.z)}
    squareBattleAreaZones.append({line1 = line1, line2=line2, line3 = line3, line4 = line4})
    segments.append(line1,line2,line3,line4)
  }, filter)

  polyBattleAreaQuery.perform(function(eid, comps){
    if (!isTagsEqual(eid, heroCaprureTag))
      return
    local points = comps["battleAreaPoints"]
    local count = points.len()
    for(local i = 0; i < count; i++) {
      local segment = {start = points[i], end = points[(i+1) % count], excludeCheckEids = [eid]}
      segments.append(segment)
    }
    polyBattleAreaZones.append(eid)
  }, filter)

  splitOverlappingSegments(segments)
  clearDuplicates(segments)

  for(local i = 0; i < segments.len(); i++)
    for(local j = i+1; j < segments.len(); j++){
        local intersectionPoint = intersection(segments[i].start, segments[i].end,
                                               segments[j].start, segments[j].end)
        if (intersectionPoint){
          local segIExcludeEids = segments[i]?.excludeCheckEids ?? []
          local segJExcludeEids = segments[j]?.excludeCheckEids ?? []
          local line1 = mkSegment(intersectionPoint, segments[i].end, segIExcludeEids)
          local line2 = mkSegment(intersectionPoint, segments[j].end, segJExcludeEids)
          segments[i] = mkSegment(segments[i].start, intersectionPoint, segIExcludeEids)
          segments[j] = mkSegment(segments[j].start, intersectionPoint, segJExcludeEids)
          segments.append(line1,line2)
        }
      }

  segments = segments.filter(function(item) {
    local checkingPoint = Point2((item.start.x + item.end.x) * 0.5, (item.start.y + item.end.y) * 0.5)
    local excludeEids = item?.excludeCheckEids ?? []
    return !(checkInSquareZone(squareBattleAreaZones,checkingPoint) || checkInPolyZone(polyBattleAreaZones, checkingPoint, excludeEids))
  })
  local polygon = buildPolygon(segments)
  battleAreasPolygon(polygon?.points)
}

::ecs.register_es("hud_battle_areas_ui_es", {
    onUpdate = @(dt, eid, comp) battleAreaHud(null, eid, comp)
  },
  { },
  { updateInterval = 1.0, tags="gameClient", after="*", before="*" }
)
return {
  activeBattleAreas = activeBattleAreasState
  battleAreasPolygon = battleAreasPolygon
}
 