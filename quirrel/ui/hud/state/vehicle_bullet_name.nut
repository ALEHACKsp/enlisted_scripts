local controlledHeroEid = require("ui/hud/state/hero_state_es.nut").controlledHeroEid

local vehicleBullet = persist("vehicleBullet", @() Watched({
  bulletName = null
  nextBulletName = null
  bulletType = null
  nextBulletType = null
}))

local function trackComponents(evt, eid, comp) {
  local hero = controlledHeroEid.value
  if (comp["gun.owner"] != hero)
    return

  local selectedVehicle = ::ecs.get_comp_val(hero,"human_anim.vehicleSelected") ?? INVALID_ENTITY_ID
  if (selectedVehicle == INVALID_ENTITY_ID) {
    vehicleBullet.update({
      bulletName = null
      nextBulletName = null
      bulletType = null
      nextBulletType = null
    })
    return
  }

  vehicleBullet.update({
    bulletName = comp["bulletName"]
    nextBulletName = comp["nextBulletName"]
    bulletType = comp["bulletType"]
    nextBulletType = comp["nextBulletType"]
  })
}

::ecs.register_es("vehicle_bullet_ui_es", { onChange = trackComponents, onInit = trackComponents, [::ecs.sqEvents.CmdTrackHeroVehicle] = trackComponents },{
  comps_track = [
    ["currentBulletId", ::ecs.TYPE_INT],
    ["nextBulletId", ::ecs.TYPE_INT],
    ["bulletName", ::ecs.TYPE_STRING],
    ["nextBulletName", ::ecs.TYPE_STRING],
    ["bulletType", ::ecs.TYPE_STRING],
    ["nextBulletType", ::ecs.TYPE_STRING],
    ["gun.owner", ::ecs.TYPE_EID]
    ]
  },{tags="gameClient"})


local vehicleGunsQuery = ::ecs.SqQuery("vehicleGunsQuery", {comps_rw=["bulletName", "nextBulletName","bulletType", "nextBulletType", "gun.owner"]})



local function trackSelectedVehicleComponents(evt, eid, comp) {
  if (comp["human_anim.vehicleSelected"] == INVALID_ENTITY_ID) {
    vehicleBullet.update({
      bulletName = null
      nextBulletName = null
      bulletType = null
      nextBulletType = null
    })
    return
  }
  vehicleGunsQuery.perform(function(gunEid, comps) {
    if (comps["gun.owner"] == eid) {
      vehicleBullet.update({
        bulletName = comps["bulletName"]
        nextBulletName = comps["nextBulletName"]
        bulletType = comps["bulletType"]
        nextBulletType = comps["nextBulletType"]
      })
    }
  })
}

::ecs.register_es("hero_vehicle_bullet_ui_es", {
  onChange = trackSelectedVehicleComponents,
  onInit = trackSelectedVehicleComponents,
  }, {
     comps_track = [["human_anim.vehicleSelected", ::ecs.TYPE_EID]],
     comps_rq=["hero"]
  },
{tags="gameClient"})

return vehicleBullet 