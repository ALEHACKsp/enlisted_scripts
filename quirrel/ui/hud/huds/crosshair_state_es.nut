local {E3DCOLOR} = require("dagor.math")
local stateEid = persist("eid", @() ::Watched(INVALID_ENTITY_ID))
local canShoot = persist("canShoot", @() ::Watched(false))
local teammateAim = persist("teammateAim", @() ::Watched(false))
local isAiming = persist("isAiming", @() ::Watched(false))
local overheat = persist("overheat", @() ::Watched(0.0))
local debugForceCrosshair = persist("debugForceCrosshair", @() Watched(false))
local crosshairType = persist("crosshairType", @() ::Watched("t_post") )
local crosshairColor = persist("crosshairColor", @() ::Watched(E3DCOLOR(255, 255, 255, 255)) )

local function trackCrossHair(evt, eid, comp) {
  stateEid(eid)
  canShoot(comp["ui_crosshair_state.canShoot"])
  teammateAim(comp["ui_crosshair_state.teammateAim"])
  isAiming(comp["ui_crosshair_state.isAiming"])
  overheat(comp["ui_crosshair_state.overheat"])
  debugForceCrosshair(comp["ui_crosshair_state.debugForceCrosshair"])
  crosshairType(comp["ui_crosshair_state.crosshairType"])
  crosshairColor(comp["ui_crosshair_state.color"])
}

::ecs.register_es("script_chrosshair_state_es",
  {
    [["onChange","onInit"]] = trackCrossHair,
    onDestroy = @(evt,eid,comp) stateEid(INVALID_ENTITY_ID)
  },
  {
    comps_track = [
      ["ui_crosshair_state.canShoot", ::ecs.TYPE_BOOL],
      ["ui_crosshair_state.teammateAim", ::ecs.TYPE_BOOL],
      ["ui_crosshair_state.isAiming", ::ecs.TYPE_BOOL],
      ["ui_crosshair_state.overheat", ::ecs.TYPE_FLOAT],
      ["ui_crosshair_state.debugForceCrosshair", ::ecs.TYPE_BOOL],
      ["ui_crosshair_state.crosshairType", ::ecs.TYPE_STRING],
      ["ui_crosshair_state.color", ::ecs.TYPE_COLOR],
    ]
  }
)

return {
  eid = stateEid
  canShoot = canShoot
  teammateAim = teammateAim
  overheat = overheat
  isAiming = isAiming
  debugForceCrosshair = debugForceCrosshair
  crosshairType = crosshairType
  crosshairColor = crosshairColor
}
 