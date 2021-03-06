local {CmdShowHitcamera, EventOnHitCameraControlEvent,
       HITCAMERA_RENDER_READY, HITCAMERA_RENDER_DONE} = require("hitcamera")

local hitcameraEid = persist("hitcameraEid", @() Watched(null))
local hitcameraTargetEid = persist("hitcameraTargetEid", @() Watched(null))
local totalMembersBeforeShot = persist("totalMembersBeforeShot", @() Watched(0))
local deadMembers = persist("deadMembers", @() Watched(0))
local {showGameMenu} = require("ui/hud/menus/game_menu.nut")

local function showHitcamera(eid, target) {
  hitcameraEid(eid)
  hitcameraTargetEid(target)
  ::ecs.g_entity_mgr.sendEvent(eid, CmdShowHitcamera())
}

local function onInit(evt, eid, comp) {
  comp["hitcamera.locked"] = true
  totalMembersBeforeShot(comp["hitcamera.totalMembersBeforeShot"])
  deadMembers(comp["hitcamera.deadMembers"])
  if (hitcameraEid.value != null) {
    // Stack up on the same target
    if (comp["hitcamera.target"] == hitcameraTargetEid.value)
      showHitcamera(eid, comp["hitcamera.target"])
    return
  }

  showHitcamera(eid, comp["hitcamera.target"])
}

local nextHitcameraQuery = ::ecs.SqQuery("nextHitcameraQuery", {
  comps_ro=[["hitcamera.target", ::ecs.TYPE_EID], ["hitcamera.renderState", ::ecs.TYPE_INT]]
  comps_rq=["hitcamera"]
})
local function onDestroy(evt, eid, comp) {
  if (eid != hitcameraEid.value)
    return

  local nextTarget = null
  nextHitcameraQuery(function (nextEid, nextComp) {
    if ((nextTarget == null || nextComp["hitcamera.target"] == nextTarget) && nextComp["hitcamera.renderState"] == HITCAMERA_RENDER_READY) {
      showHitcamera(nextEid, nextComp["hitcamera.target"])
      nextTarget = nextComp["hitcamera.target"]
    }
  })

  if (nextTarget == null) {
    hitcameraEid(null)
    hitcameraTargetEid(null)
  }
}

local function onChange(evt, eid, comp) {
  local renderState = comp["hitcamera.renderState"]
  if (renderState == HITCAMERA_RENDER_DONE)
    comp["hitcamera.locked"] = false
}

local function onControlEvent(evt, eid, comp) {
  // local target = evt[0]
  // local hitResult = evt[2]
}

::ecs.register_es("hitcamera_ui_es", {
  onInit = onInit,
  onDestroy = onDestroy,
  onChange = onChange,
  [EventOnHitCameraControlEvent] = onControlEvent,
},
{
  comps_track=[["hitcamera.renderState", ::ecs.TYPE_INT],["hitcamera.target", ::ecs.TYPE_EID]]
  comps_rw=[["hitcamera.locked", ::ecs.TYPE_BOOL]]
  comps_ro=[["hitcamera.totalMembersBeforeShot", ::ecs.TYPE_INT], ["hitcamera.deadMembers", ::ecs.TYPE_INT]]
  comps_rq=["hitcamera"]
},
{ tags="gameClient", before="hitcamera_destroy_non_locked_es", after="entities_in_victim_tank_es" })

return {
  hitcameraEid = hitcameraEid
  hitcameraTargetEid = hitcameraTargetEid
  isVisible = ::Computed(@() hitcameraEid.value != null && !showGameMenu.value)
  totalMembersBeforeShot = totalMembersBeforeShot
  deadMembers = deadMembers
} 