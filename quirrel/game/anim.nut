local {Point3, Quat, euler_to_quat} = require("dagor.math")
local app = require("net")
local animevents = require("animevents")

::anim <- {}
::anim.set_rotation <- function (eid, ang_speed_yaw, ang_speed_pitch, ang_speed_roll, local_space = false) { // in degrees, not radians

  local start = Point3(0,0,0)
  local end = Point3(ang_speed_yaw/57.29577951308232, ang_speed_pitch/57.29577951308232, ang_speed_roll/57.29577951308232)
  local endLen = end.length()
  local endScale = 1
  if (endLen > 1) {
    endScale = (1./(endLen*10 + 0.00001))
    end = Point3(end.x*endScale, end.y*endScale, end.z*endScale) //degs
  }

  local startQuat = euler_to_quat(start)
  local endQuat = euler_to_quat(end)

  if (local_space) {
    local transform = ::ecs.get_comp_val(eid, "transform")
    if (transform) {
      local initialRotationQuat = Quat(transform).normalize()
      startQuat = initialRotationQuat*startQuat
      endQuat = initialRotationQuat*endQuat
    }
  }
  local startTime = app.get_sync_time()
  if (startTime<0)
    startTime = 0
  if (endLen > 0) {
    ::ecs.g_entity_mgr.sendEvent(eid, animevents.CmdResetRotAnim(startQuat, startTime, ANIM_EXTRAPOLATED))
    ::ecs.g_entity_mgr.sendEvent(eid, animevents.CmdAddRotAnim(endQuat, endScale, true))
  } else
    ::ecs.g_entity_mgr.sendEvent(eid, animevents.CmdResetRotAnim(startQuat, startTime, ANIM_SINGLE))
}

::anim.reset_rotation <- function (eid, ang_speed_yaw, ang_speed_pitch, ang_speed_roll) {// in degrees, not radians

  local startTime = app.get_sync_time()
  ::ecs.g_entity_mgr.sendEvent(eid, animevents.CmdResetRotAnim(euler_to_quat(Point3(ang_speed_yaw, ang_speed_pitch, ang_speed_roll)), startTime, ANIM_SINGLE))
}

::print("anim.nut intialized\n")
 