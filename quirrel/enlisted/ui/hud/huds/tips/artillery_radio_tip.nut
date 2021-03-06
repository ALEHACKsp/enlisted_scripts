local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {curWeapon} = require("ui/hud/state/hero_state.nut")
local {isRadioMode} = require("enlisted/ui/hud/state/enlisted_hero_state.nut")
local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")

local tip = tipCmp({
  text = loc("tips/use_radio", "Use radio")
  inputId = "Human.Shoot"
})

local showTip = ::Computed(@() !inVehicle.value && !isRadioMode.value && curWeapon.value?.weapType == "radio")

local function use_radio() {
  local children = showTip.value ? tip : null
  return {
    watch = [showTip]
    size=SIZE_TO_CONTENT
    children = children
  }
}

return use_radio
 