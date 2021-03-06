local {ceil} = require("math")
local {DM_EFFECT_FIRE, DM_EFFECT_EXPL} = require("dm")

local {EventOnVehicleDamaged, EventOnVehicleDamageEffects} = require("vehicle")

local victimState = persist("victimVehicleHp", @() Watched({
  vehicle = INVALID_ENTITY_ID
  vehicleIconName = null
  damage = 0.0
  hp = 0.0
  maxHp = 0.0
  show = false
  effects = 0
}))

local heroState = persist("heroVehicleHp", @() Watched({
  vehicle = INVALID_ENTITY_ID
  hp = 0.0
  maxHp = 0.0
  isBurn = false
}))

::ecs.register_es("ui_vehicle_hp_es", {
  [EventOnVehicleDamaged] = function(evt, eid, comp) {
    local state = victimState.value

    local vehicle = evt[1]
    local damage = evt[2]
    local hp = evt[3]
    local maxHp = evt[4]

    local totalDamage = damage + (vehicle == state.vehicle && state.show ? state.damage : 0)
    local data = {
      show = true
      vehicle = vehicle
      damage = totalDamage
      hp = hp
      maxHp = maxHp
      vehicleIconName = null
    }
    if (vehicle != state.vehicle || !state.show)
      data.__update({effects = 0})

    victimState.update(@(v) v.__update(data))
  },
  [EventOnVehicleDamageEffects] = function(evt, eid, comp) {
    local vehicle = evt[1]
    local effects = evt[2]
    local data = {
      show = true
      vehicle = vehicle
      effects = effects
      vehicleIconName = null
    }

    local state = victimState.value

    if (vehicle != state.vehicle || !state.show)
      data.__update({hp = 0, maxHp = 0, damage = 0})

    victimState.update(@(v) v.__update(data))
  }
},
{comps_rq=["hero"]})

local function trackHeroVehicle(evt, eid, comp) {
  heroState.update(function(v) {
    v.vehicle = eid
    v.hp = ceil(comp["vehicle.hp"]).tointeger()
    v.maxHp = ceil(comp["vehicle.maxHp"]).tointeger()
    v.isBurn = comp["fire_damage.isBurn"]
  })
}

local resetHeroVehicle = @(evt, eid, comp)
  heroState.update({
    vehicle = INVALID_ENTITY_ID
    hp = 0.0
    maxHp = 0.0
    isBurn = false
  })

::ecs.register_es("ui_hero_vehicle_hp_es", {
  onInit = trackHeroVehicle,
  onChange = trackHeroVehicle,
  onDestroy = resetHeroVehicle,
  [::ecs.EventComponentsDisappear] = resetHeroVehicle,
},
{
  comps_ro=[
    ["vehicle.maxHp", ::ecs.TYPE_FLOAT],
    ["fire_damage.isBurn", ::ecs.TYPE_BOOL],
  ]
  comps_rq=["heroVehicle"]
  comps_track=[["vehicle.hp", ::ecs.TYPE_FLOAT], ["fire_damage.isBurn", ::ecs.TYPE_BOOL]]
})

::ecs.register_es("ui_hero_vehicle_on_change_es", {
  onDestroy = resetHeroVehicle,
  onChange = function(evt, eid, comp) {
    if (!comp.isInVehicle)
      resetHeroVehicle(evt, eid, comp)
  }
},
{
  comps_rq=["hero"]
  comps_track=[["isInVehicle", ::ecs.TYPE_BOOL]]
})

console.register_command(@() victimState.update(@(v) v.show = true), "vehicle_hp.repeat_last_hit")

console.register_command(
@()
  victimState.update(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 300.0
    v.damage = 150.0
    v.maxHp = 450.0
  }),
"vehicle_hp.debug_hit")

console.register_command(
@()
  victimState.update(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 300.0
    v.damage = 150.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_FIRE)
  }),
"vehicle_hp.debug_fire")

console.register_command(
@()
  victimState.update(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = 0
  }),
"vehicle_hp.debug_destroy")

console.register_command(
@()
  victimState.update(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_FIRE)
  }),
"vehicle_hp.debug_destroy_fire")

console.register_command(
@()
  victimState.update(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_EXPL)
  }),
"vehicle_hp.debug_destroy_expl")

return { victim = victimState, hero = heroState } 