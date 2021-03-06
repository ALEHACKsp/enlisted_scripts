local minimapCaptureZones = require("huds/minimap_cap_zones.nut")
local artilleryZones = require("ui/hud/huds/minimap/minimap_artillery_zones.nut")
local battleAreas = require("enlisted/ui/hud/huds/minimap_battle_areas.nut")
local resupplyZones = require("enlisted/ui/hud/huds/minimap_resupply_zones.nut")
local minimapSquadOrders = require("enlisted/ui/hud/huds/minimap_squad_orders.nut")
local {user_points} = require("ui/hud/state/user_points.nut")
local {mkUserPoints, user_points_ctors} = require("ui/hud/huds/minimap/user_points_ctors.nut")
local {teammatesMarkers} = require("huds/minimap_teammates.nut")
local {mkPointMarkerCtor} = require("ui/hud/huds/minimap/components/minimap_markers_components.nut")
local {TEAM0_COLOR_FG} = require("ui/hud/style.nut")
local mkBuildingIcon = require("enlisted/ui/hud/huds/building_icons.nut")
local aircraftMapMarkers = require("enlisted/ui/hud/huds/aircraft_map_markers.nut")
local engineerMapMarkers = require("enlisted/ui/hud/huds/engineer_map_markers.nut")
local mortarMarkers = require("common_shooter/ui/hud/huds/mortar_map_markers.nut")

local { mmChildrensCtors } = require("ui/hud/huds/minimap/minimap_state.nut")

local tankSz = [sh(1.4), sh(1.4)].map(@(v) v.tointeger())
local tankMark = ::Picture("!ui/skin#tank_icon.svg:{0}:{1}:K".subst(tankSz[0].tointeger(), tankSz[1].tointeger()))

local mkColors = @(color) {myHover = color, myDef = color, foreignHover = color, foreignDef = color}

user_points_ctors = user_points_ctors.__merge({
  enemy_vehicle_user_point = mkPointMarkerCtor({
    image = tankMark,
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    size = tankSz
  })

  controlledTank = mkPointMarkerCtor({
    image = tankMark,
    colors = mkColors(Color(200, 200, 0))
    size = tankSz
    valign = ALIGN_CENTER
  })

  squadTank = mkPointMarkerCtor({
    image = tankMark,
    colors = mkColors(Color(0, 200, 0))
    size = tankSz
    valign = ALIGN_CENTER
  })

  friendlyTank = mkPointMarkerCtor({
    image = tankMark,
    colors = mkColors(TEAM0_COLOR_FG)
    size = tankSz
    valign = ALIGN_CENTER
  })

  building_point = mkBuildingIcon
})

mmChildrensCtors([
  battleAreas
  artilleryZones
  mortarMarkers
  resupplyZones
  minimapSquadOrders
  minimapCaptureZones
  aircraftMapMarkers
  engineerMapMarkers
  mkUserPoints(user_points_ctors, user_points)
  teammatesMarkers
])
 