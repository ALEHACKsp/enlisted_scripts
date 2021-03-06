local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {curWeapon} = require("ui/hud/state/hero_state.nut")
local {isDowned} = require("ui/hud/state/hero_state_es.nut")
local {tipCmp} = require("tipComponent.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")

local tip = tipCmp({
  text = loc("tips/throw_grenade", "Throw grenade")
  inputId = "Human.Shoot"
})

local function throw_grenade() {
  local children = null
  if (showPlayerHuds.value && !inVehicle.value && curWeapon.value?.grenadeType != null && !isDowned.value) {
    children = tip
  }
  return {
    watch = [inVehicle, curWeapon, showPlayerHuds, isDowned]
    size=SIZE_TO_CONTENT
    children = children
  }
}

return throw_grenade
 