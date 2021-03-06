local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")

local overheat = persist("overheat", @() Watched(0))

local function trackComponents(evt, eid, comp) {
  local hero = watchedHeroEid.value
  if (::ecs.get_comp_val(hero, "human_anim.vehicleSelected") == INVALID_ENTITY_ID) {
    overheat.update(0)
    return
  }
  if (comp["gun.owner"] == hero && comp["gun.overheat"] > 0)
    overheat.update(comp["gun.overheat"])
}

::ecs.register_es("turret_overheat_ui_es", {
    onChange = trackComponents,
    onInit = trackComponents,
    onDestroy = trackComponents }, {
    comps_track = [
      ["gun.overheat", ::ecs.TYPE_FLOAT]
    ]
    comps_ro = [
      ["gun.owner", ::ecs.TYPE_EID]
    ],
    comps_rq = [
      "isTurret"
    ]
  },
  {tags="gameClient"}
)

local turretQuery = ::ecs.SqQuery("turretQuery", {
  comps_ro=[["gun.overheat", ::ecs.TYPE_FLOAT]]
  comps_rq = ["isTurret"]
})

local function trackSelectedVehicleComponents(evt, eid, comp) {
  overheat.update(0)
  local vehicleEid = comp["human_anim.vehicleSelected"]
  local turretEids = ecs.get_comp_val(vehicleEid, "turret_control.gunEids")?.getAll() ?? []
  foreach (turretEid in turretEids)
    if (turretQuery.perform(turretEid, function(eid, comp) { overheat.update(comp["gun.overheat"]); return true; }))
      break
}

::ecs.register_es("hero_vehicle_turret_overheat_ui_es", {
    onChange = trackSelectedVehicleComponents,
    onInit = trackSelectedVehicleComponents,
  },
  {
    comps_track = [["human_anim.vehicleSelected", ::ecs.TYPE_EID]]
    comps_rq = ["hero"]
  },
  {tags="gameClient"}
)

return overheat
 