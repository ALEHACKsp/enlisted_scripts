local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {curWeapon} = require("ui/hud/state/hero_state.nut")
local {isAlive} = require("ui/hud/state/hero_state_es.nut")
local {isAiming} = require("ui/hud/huds/crosshair_state_es.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local {tipCmp} = require("tipComponent.nut")

local tip = tipCmp({
  inputId = "Human.Shoot"
  text = ::loc("tips/prevent_reloading")
  textColor = Color(100,140,200,110)
})

local isPreventReloadingVisible = ::Computed(@()
  showPlayerHuds.value
  && isAiming.value
  && isAlive.value
  && !inVehicle.value
  && (curWeapon.value?.curAmmo ?? 0) > 0
  && curWeapon.value?.firingMode == "bolt_action"
  && curWeapon.value?.mods.scope.itemPropsId != null)

return @() {
  watch = isPreventReloadingVisible
  size = SIZE_TO_CONTENT
  children = isPreventReloadingVisible.value ? tip : null
}
 