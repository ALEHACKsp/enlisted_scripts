local { makeArrow } = require("ui/hud/huds/hud_markers/components/hud_markers_components.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {controlledVehicleEid} = require("ui/hud/state/vehicle_state.nut")

local colorTeammateInner = Color(150,160,255,180)
local colorTeammateOuter = Color(150,160,255,20)
local colorEnemyOuter = Color(167, 55, 76, 255)
local colorEnemyInner = Color(167, 55, 76, 255)
local colorUnidentifiedInner = Color(80, 80, 80, 255)
local colorUnidentifiedOuter = Color(80, 80, 80, 255)

local defTransform = {}

local unitIconSize = [sh(1.1), sh(1.5)].map(@(v) v.tointeger())

local baseIcon = @(colorOuter, colorInner) {
  key = "icon"
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = ::Picture($"ui/skin#unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
  size = unitIconSize
  minDistance = 0.5
  transform = { translate = [0, hdpx(-10)] }

  children = {
    rendObj = ROBJ_IMAGE
    color = colorInner
    image = ::Picture($"ui/skin#unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
    size = unitIconSize
  }
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
}

local teammateIcon = baseIcon(colorTeammateOuter, colorTeammateInner)
local enemyIcon    = baseIcon(colorEnemyOuter, colorEnemyInner)
local unidentifiedIcon = baseIcon(colorUnidentifiedOuter, colorUnidentifiedInner)

return function aircraft(eid, marker) {
  local {isIdentified, isFriendly} = marker
  local isHeroPlane = ::Computed(@() controlledVehicleEid.value == eid)
  local icon = !isIdentified ? unidentifiedIcon
               : isFriendly ? teammateIcon
               : enemyIcon
  local color = !isIdentified ? colorUnidentifiedInner
                : isFriendly ? colorTeammateInner
                : colorEnemyInner
  local arrow = makeArrow({ color = color })

  return @() isHeroPlane.value ? null : {
    data = {
      eid = eid
      minDistance = 0.5
      maxDistance = 10000
      distScaleFactor = 0.3
      clampToBorder = true
      yOffs = 1.2
    }

    key = $"aircraft_marker_{eid}"
    sortOrder = eid

    transform = defTransform

    watch = [isHeroPlane, localPlayerTeam]

    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    children = [icon, arrow]
  }
}
 