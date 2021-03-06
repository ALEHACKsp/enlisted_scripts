local {traceray_normalized} = require("dacoll.trace")
local {Point3, TMatrix} = require("dagor.math")
local {CmdDeleteMapUserPoint, CmdCreateMapUserPoint} = require("mapuserpointsevents")
local {sound_play=null} = require_optional("sound")


local find_points_to_deleteQuery = ::ecs.SqQuery("find_points_to_deleteQuery", {
  comps_rq = ["hudUserPoint"],
  comps_ro = [["userPointOwner", ::ecs.TYPE_EID], ["transform", ::ecs.TYPE_MATRIX], ["deleteAngle", ::ecs.TYPE_FLOAT]]
})

local find_crosshair_stateQuery = ::ecs.SqQuery("find_crosshair_stateQuery", {
  comps_ro = [["ui_crosshair_state.canShoot", ::ecs.TYPE_BOOL], ["ui_crosshair_state.isAiming", ::ecs.TYPE_BOOL]]})


local function find_and_delete_point(player_eid, trace_pos, trace_dir){
  return find_points_to_deleteQuery.perform(function(eid, comp){
      local dir = comp.transform.getcol(3) - trace_pos
      local dist = dir.length()
      dir = dist > 0.0 ? Point3(dir.x/dist, dir.y/dist, dir.z/dist) : Point3(1.0,0.0,0.0)
      local angle = 1.0 - (dir * trace_dir)
      if (angle * (::max(dist,1.0)) < comp.deleteAngle){
        ::ecs.g_entity_mgr.sendEvent(eid, CmdDeleteMapUserPoint())
        return true
      }
    },"eq(userPointOwner, {0}:eid)".subst(player_eid))
}

local function get_trace_tm(canShoot, aim_tm, aim_dir){
  if(canShoot)
    return aim_tm

  local upDir = Point3(0.0, 1.0, 0.0)
  local leftDir = upDir % aim_dir
  leftDir.normalize()

  local tm = TMatrix()
  tm.setcol(0, aim_dir)
  tm.setcol(1, upDir)
  tm.setcol(2, leftDir)
  tm.setcol(3, aim_tm.getcol(3))
  return tm
}

local function set_mark(name, plEid, traceTm){
  local traceDir = traceTm.getcol(0)
  local tracePos = traceTm.getcol(3)
  local t = traceray_normalized(tracePos, traceDir, 2000)
  local markPos = t >= 0.0 ? traceTm * Point3(t, 0.0, 0.0) : Point3(0.0,0.0,0.0)
  if(!find_and_delete_point(plEid, tracePos, traceDir))
    ::ecs.g_entity_mgr.sendEvent(plEid, CmdCreateMapUserPoint(markPos, name))
}

local function onCmdSetMarkMain(evt, eid, ext_comp) {
  find_crosshair_stateQuery.perform(function(eid, comp) {
    local traceTm = get_trace_tm(comp["ui_crosshair_state.canShoot"], ext_comp["human.aimTm"], ext_comp["camera.lookDir"])
    set_mark(comp["ui_crosshair_state.isAiming"] ? "enemy" : "main", evt.data.plEid, traceTm)
    return
  })
}


local function onCmdSetMarkEnemy(evt, eid, ext_comp) {
  find_crosshair_stateQuery.perform(function(eid, comp) {
    local traceTm = get_trace_tm(comp["ui_crosshair_state.canShoot"], ext_comp["human.aimTm"], ext_comp["camera.lookDir"])
    set_mark("enemy", evt.data.plEid, traceTm)
    return
  })
}


local function onCmdCreateMapPoint(evt, eid, comp) {
    local len = 500
    local upmostPos = Point3(evt.data.x, len, evt.data.z)
    local t = traceray_normalized(upmostPos, Point3(0.0, -1.0, 0.0), len)
    upmostPos.y = t >= 0.0 ? len - t : 0.0
    ::ecs.g_entity_mgr.sendEvent(comp["eid"], CmdCreateMapUserPoint(upmostPos, "way_point"))
    if (sound_play)
      sound_play("ui/map_command")
}


::ecs.register_es("user_points_for_player_es",
  {[::ecs.sqEvents.CmdCreateMapPoint] = onCmdCreateMapPoint},
  {comps_ro = [["eid", ::ecs.TYPE_EID]]})


::ecs.register_es("user_points_for_pawn_es",
  {
    [::ecs.sqEvents.CmdSetMarkMain] = onCmdSetMarkMain,
    [::ecs.sqEvents.CmdSetMarkEnemy] = onCmdSetMarkEnemy
  },
  {comps_ro = [
    ["human.aimTm", ::ecs.TYPE_MATRIX],
    ["camera.lookDir", ::ecs.TYPE_POINT3]
  ]}) 