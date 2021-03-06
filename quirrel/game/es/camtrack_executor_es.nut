local camera = require_optional("camera")
if (camera == null)
  return

local DataBlock = require("DataBlock")
local animevents = require("animevents")
local app = require("net")
local math = require("std/math_ex.nut")
local dir_to_quat = math.dir_to_quat


local anim_trackQuery = ::ecs.SqQuery("anim_trackQuery", {comps_rq = ["screen_fade", "anim_track_on"] })
local function start(comp) {
  local fileName = comp["camtracks.file"]
  local tracksBlk = DataBlock()
  tracksBlk.load(fileName)
  local tracks = tracksBlk % "track"

  if (tracks.len() == 0)
    return

  local fadeInTime = comp["camtracks.fade_in_time"]
  local fadeOutTime = comp["camtracks.fade_out_time"]


  anim_trackQuery.perform(function(fadeEid, comp) {
    local cameraEid = camera.get_cur_cam_entity()
    ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdResetAttrFloatAnim(::ecs.calc_hash("screen_fade"), app.get_sync_time(), ANIM_CYCLIC))
    ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdResetPosAnim(tracks[0].from_pos, app.get_sync_time(), ANIM_CYCLIC))
    ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdResetRotAnim(dir_to_quat(tracks[0].from_dir), app.get_sync_time(), ANIM_CYCLIC))
    ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdResetAttrFloatAnim(::ecs.calc_hash("fov"), app.get_sync_time(), ANIM_CYCLIC))

    foreach (track in tracks) {
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(1.0, 0, true))
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(0.0, fadeInTime, true))
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(0.0, track.duration - fadeOutTime - fadeInTime, true))
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(1.0, fadeOutTime, true))
      ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddPosAnim(track.from_pos, 0, true))
      ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddPosAnim(track.to_pos, track.duration, true))
      ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddRotAnim(dir_to_quat(track.from_dir), 0, true))
      ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddRotAnim(dir_to_quat(track.to_dir), track.duration, true))
      ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddAttrFloatAnim(track.from_fov, 0, true))
      ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddAttrFloatAnim(track.to_fov, track.duration, true))
    }
  })

  comp["camtracks.playing"] = true
}


local function startCameraTracks(evt, eid, comp) {
  if (!comp["camtracks.playing"])
    start(comp)
}

local function stopCameraTracks(evt, eid, comp) {

  local fadeOutTime = comp["camtracks.fade_out_time"]

  if (comp["camtracks.playing"]) {
    local cameraEid = camera.get_cur_cam_entity()
    ::ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdStopAnim())

    anim_trackQuery.perform(function(fadeEid, comp) {
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdResetAttrFloatAnim(::ecs.calc_hash("screen_fade"), app.get_sync_time(), ANIM_SINGLE))
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(1.0, 0, true))
      ::ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(0.0, fadeOutTime, true))
    })

    comp["camtracks.playing"] = false
  }
}


::ecs.register_es("camtrack_executor_es", {
    [::ecs.sqEvents.EventStartCameraTracks] = startCameraTracks,
    [::ecs.sqEvents.EventStopCameraTracks] = stopCameraTracks,
  },
  {
    comps_rw = [
      ["camtracks.playing", ::ecs.TYPE_BOOL],
    ]
    comps_ro = [
      ["camtracks.file", ::ecs.TYPE_STRING],
      ["camtracks.fade_in_time", ::ecs.TYPE_FLOAT],
      ["camtracks.fade_out_time", ::ecs.TYPE_FLOAT],
    ]
  }
)

 