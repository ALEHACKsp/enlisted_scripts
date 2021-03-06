local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local {inVehicle, isGunner, isDriver} = require("ui/hud/state/vehicle_state.nut")

return function () {
  local tip = null
  if (inVehicle.value) {
    local text = null
    if (isDriver.value) {
      text = ::loc("hud/vehicle_control_hint/driver", "You're controlling vehcile's movement")
    } else if (isGunner.value) {
      text = ::loc("hud/vehicle_control_hint/gunner", "You're controlling vehcile's main turret")
    }

    if (text != null) {
      tip = tipCmp({text = text, font = Fonts.small_text})
    }
  }

  return {
    watch = [
      inVehicle
      isGunner
      isDriver
    ]

    children = tip
  }
}
 