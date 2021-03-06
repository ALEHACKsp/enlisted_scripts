local {Point2} = require("dagor.math")
local {watchedHeroEid, controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {controlledVehicleEid} = require("ui/hud/state/vehicle_state.nut")

local colorTeammateInner = Color(150,160,255,180)
local colorTeammateOuter = Color(150,160,255,20)
local colorSquadmateInner = Color(150,255,160,180)
local colorSquadmateOuter = Color(150,255,160,20)

local defTransform = {}

local unitIconSize = [sh(1), sh(1.25)].map(@(v) v.tointeger())

local mkIcon = @(colorInner, colorOuter) {
  key = $"icon_{colorInner}_{colorOuter}"
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = ::Picture($"ui/skin#unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
  size = unitIconSize
  minDistance = 0.5

  children = {
    rendObj = ROBJ_IMAGE
    color = colorInner
    image = ::Picture($"ui/skin#unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
    size = unitIconSize
  }
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
}

local squadmateIcon = mkIcon(colorSquadmateInner, colorSquadmateOuter)
local teammateIcon = mkIcon(colorTeammateInner, colorTeammateOuter)


local function unit(eid, info){
  if (!info.isAlive)
    return null
  local squadEid = ::ecs.get_comp_val(eid, "squad_member.squad") ?? INVALID_ENTITY_ID
  local isSquadmate = (squadEid!=INVALID_ENTITY_ID && squadEid >= 0 && squadEid == ::ecs.get_comp_val(watchedHeroEid.value, "squad_member.squad"))

  local vehicle = info?["human_anim.vehicleSelected"] ?? INVALID_ENTITY_ID
  local isInPlane = ::ecs.get_comp_val(vehicle, "airplane", null) != null
  local maxDist = isInPlane ? 15.0 : 1000

  return function(){
    if (watchedHeroEid.value==eid)
      return {watch = watchedHeroEid}
    if (vehicle != INVALID_ENTITY_ID && vehicle == controlledVehicleEid.value)
      return {watch = controlledVehicleEid}

    return {
      data = {
        eid = eid
        minDistance = 1
        maxDistance = maxDist
        distScaleFactor = 0.5
        clampToBorder = true
        yOffs = 0.25
        opacityRangeX = Point2(0.25, 0.35)
        opacityRangeY = Point2(0.25, 0.75)
      }

      key = $"unit_marker_{eid}"
      sortOrder = eid
      watch = [watchedHeroEid, controlledHeroEid, controlledVehicleEid]
      transform = defTransform

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children = isSquadmate ? squadmateIcon : teammateIcon
    }
  }
}

return {
  teammate_ctor = unit
} 