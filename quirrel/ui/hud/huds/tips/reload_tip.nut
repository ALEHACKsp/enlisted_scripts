local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {needReload} = require("ui/hud/state/hero_state.nut")
local {isAlive} = require("ui/hud/state/hero_state_es.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local isMachinegunner = require("ui/hud/state/machinegunner_state.nut")
local {tipCmp} = require("tipComponent.nut")

local color0 = Color(200,40,40,110)
local color1 = Color(200,200,40,180)

local tip = tipCmp({
  inputId = "Human.Reload"
  text = ::loc("tips/need_reload")
  sound = {
    attach = {name="ui/need_reload", vol=0.1}
  }
  textColor = Color(200,40,40,110)
  textAnims = [
    { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  ]
})
local showReloadTip = ::Computed(@() showPlayerHuds.value && needReload.value && !inVehicle.value && isAlive && !isMachinegunner.value)
return @() {
  watch = showReloadTip
  size = SIZE_TO_CONTENT
  children = showReloadTip.value ? tip : null
}
 