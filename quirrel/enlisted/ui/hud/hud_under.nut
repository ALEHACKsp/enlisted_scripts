local {makeMarkersLayout} = require("ui/hud/components/hudMarkersLayout.nut")

local {active_grenades} = require("ui/hud/state/active_grenades.nut")
local {grenade_marker} = require("ui/hud/huds/hud_markers/grenade_ctor.nut")

local {teammate_ctor} = require("hud_markers/teammate_ctor.nut")
local {teammatesAvatars} = require("ui/hud/state/human_teammates.nut")

local {user_point_ctor} = require("hud_markers/user_points_ctor.nut")
local {user_points} = require("ui/hud/state/user_points.nut")

local squad_order_ctor = require("hud_markers/squad_order_ctor.nut")
local {squad_orders} = require("state/squad_orders.nut")

local {aircraft_markers} = require("state/aircraft_markers.nut")
local aircraft_ctor = require("hud_markers/aircraft_ctor.nut")

local {spawn_zone_markers} = require("state/spawn_zones_markers.nut")
local spawn_zone_ctor = require("hud_markers/spawn_zone_ctor.nut")

local markersCtorsAndState = {
  [active_grenades] = grenade_marker,
  [teammatesAvatars] = teammate_ctor,
  [user_points] = user_point_ctor,
  [squad_orders] = squad_order_ctor,
  [aircraft_markers] = aircraft_ctor,
  [spawn_zone_markers] = spawn_zone_ctor,
}

local arrowsPadding = sh(3)
return makeMarkersLayout(markersCtorsAndState, 1.2*arrowsPadding)
 