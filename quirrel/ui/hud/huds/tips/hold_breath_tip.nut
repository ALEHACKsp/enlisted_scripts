local {curWeapon} = require("ui/hud/state/hero_state.nut")
local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {isHoldBreath, isAlive} = require("ui/hud/state/hero_state_es.nut")
local {isAiming} = require("ui/hud/huds/crosshair_state_es.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local isMachinegunner = require("ui/hud/state/machinegunner_state.nut")
local {tipCmp} = require("tipComponent.nut")

local tip = tipCmp({
  inputId = "Human.HoldBreath"
  text = ::loc("tips/hold_breath_to_aim")
  textColor = Color(100,140,200,110)
})

local showHoldBrief = ::Computed(@()
  showPlayerHuds.value
  && isAiming.value
  && !isMachinegunner.value
  && !isHoldBreath.value
  && isAlive.value
  && !inVehicle.value
  && (curWeapon.value?.curAmmo ?? 0) > 0)

return @() {
  watch = showHoldBrief
  size = SIZE_TO_CONTENT
  children = showHoldBrief.value ? tip : null
}
 