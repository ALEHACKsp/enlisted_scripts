local {aircraft_markers} = require("enlisted/ui/hud/state/aircraft_markers.nut")
local {controlledVehicleEid} = require("ui/hud/state/vehicle_state.nut")
local {TEAM0_COLOR_FG, TEAM1_COLOR_FG} = require("ui/hud/style.nut")

local iconSz = [sh(1.4), sh(1.4)].map(@(v) v.tointeger())
local iconImg = ::Picture("!ui/skin#aircraft_icon.svg:{0}:{1}:K".subst(iconSz[0].tointeger(), iconSz[1].tointeger()))

local heroColor = Color(200,200,0,250)
local unidentifiedColor = Color(80, 80, 80, 250)
local friendlyColor = TEAM0_COLOR_FG
local enemyColor = TEAM1_COLOR_FG


local function mkAircraftMapMarker(eid, marker, options = null) {
  local isHeroPlane = ::Computed(@() controlledVehicleEid.value == eid)
  local {isIdentified, isFriendly} = marker

  return @() {
    data = {
      eid = eid
      minDistance = 0.7
      maxDistance = 2000
      clampToBorder = true
      dirRotate = true
    }
    transform = {}
    children = [{
      rendObj = ROBJ_IMAGE
      size = iconSz
      color = isHeroPlane.value ? heroColor
            : !isIdentified ? unidentifiedColor
            : isFriendly ? friendlyColor
            : enemyColor
      image = iconImg
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {
        rotate=45.0
      }
    }]
    watch=[isHeroPlane]
  }
}

return Computed(@() { ctor = @(p) aircraft_markers.value.reduce(@(res, info, eid) res.append(mkAircraftMapMarker(eid, info, p)), [])}) 