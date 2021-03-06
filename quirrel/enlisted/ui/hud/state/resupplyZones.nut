local { TEAM_UNASSIGNED } = require("team")
local { isEqual } = require("std/underscore.nut")
local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {inGroundVehicle, inPlane} = require("ui/hud/state/vehicle_state.nut")

local resupplyZones = persist("resupplyZones", @() ::Watched({}))
local heroActiveResupplyZonesEids = ::Watched([])


local function updateEids(...) {
  local watchedHeroTeam = ::ecs.get_comp_val(watchedHeroEid.value, "team") ?? TEAM_UNASSIGNED
  if (!inGroundVehicle.value && !inPlane.value) {
    heroActiveResupplyZonesEids([])
    return
  }
  local applicableForVehicle = @(z) (inPlane.value && ::ecs.get_comp_val(z.eid, "planeResupply") != null) ||
                                    (inGroundVehicle.value && ::ecs.get_comp_val(z.eid, "groundVehicleResupply") != null)
  local applicableForTeam = @(z) z.team == TEAM_UNASSIGNED || z.team == watchedHeroTeam
  local heroZoneEids = resupplyZones.value.filter(@(z) z.active && applicableForTeam(z) && applicableForVehicle(z)).keys()
  if (!isEqual(heroZoneEids, heroActiveResupplyZonesEids.value))
    heroActiveResupplyZonesEids(heroZoneEids)
}
[resupplyZones, inGroundVehicle, inPlane].map(@(v) v.subscribe(updateEids))
updateEids()


local function onResupplyZoneInitialized(evt, eid, comp) {
  local zone = {
    eid = eid
    active   = comp["active"]
    icon     = comp["zone.icon"]
    ui_order = comp["ui_order"]
    caption  = comp["zone.caption"]
    radius   = comp["sphere_zone.radius"]
    team     = comp["resupply_zone.team"]
  }
  resupplyZones[eid] <- zone
}

local function onResupplyZoneChanged(evt, eid, comp) {
  local zone = resupplyZones.value?[eid]

  if (zone==null)
    return

  local updatedZone = clone zone

  updatedZone.active = comp["active"]
  updatedZone.radius = comp["sphere_zone.radius"]
  updatedZone.ui_order = comp["ui_order"]
  updatedZone.team = comp["resupply_zone.team"]

  resupplyZones(@(v) v[eid] = updatedZone)
}

local function onResupplyZoneDestroy(evt, eid, comp) {
  if (eid in resupplyZones.value)
    resupplyZones(@(v) delete v[eid])
}


::ecs.register_es("resupply_zones_ui_state_es",
  {
    onChange = onResupplyZoneChanged,
    onInit = onResupplyZoneInitialized,
    onDestroy = onResupplyZoneDestroy,
  },
  {
    comps_ro = [
      ["zone.icon", ::ecs.TYPE_STRING, ""],
      ["zone.caption", ::ecs.TYPE_STRING, ""],
    ]
    comps_track = [
      ["active", ::ecs.TYPE_BOOL],
      ["resupply_zone.team", ::ecs.TYPE_INT],
      ["ui_order", ::ecs.TYPE_INT, 0],
      ["sphere_zone.radius", ::ecs.TYPE_FLOAT, 0],
    ],
    comps_rq = ["resupplyZone"]
  },
  { tags="gameClient" }
)


return {
  resupplyZones = resupplyZones
  heroActiveResupplyZonesEids = heroActiveResupplyZonesEids
}
 