local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local { inGroundVehicle, isDriver } = require("ui/hud/state/vehicle_state.nut")
local {mkHasBinding } = require("ui/hud/components/controlHudHint.nut")
local {textListFromAction, keysImagesMap} = require("ui/control/formatInputBinding.nut")
local {isGamepad} = require("ui/control/active_controls.nut")

local PASSENGER_TIPS = ["Human.SeatNext"]
local DRIVER_TIPS = ["Human.SeatNext", "Vehicle.Brake", "Vehicle.Accel", "Vehicle.Steer", "Vehicle.Throttle", "Vehicle.Horn"]

local watches = {}
foreach (key in [].extend(DRIVER_TIPS).extend(PASSENGER_TIPS))
  watches[key] <- mkHasBinding(key)

local showTip = Watched(true)
local animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
local defWatches = [inGroundVehicle, isDriver]
local fullWatches = [showTip].extend(defWatches).extend(watches.values())

const showTipFor = 15
inGroundVehicle.subscribe(@(v) showTip(v))
local hideTip = @() ::gui_scene.setTimeout(showTipFor, @() showTip(false))
showTip.subscribe(function(v) {if(v) hideTip()})
hideTip()

local function prepareTipCmp(key) {
  if (isGamepad.value) {
    local hasImage = textListFromAction(key, 1).findvalue(@(e) e in keysImagesMap) != null
    if (!hasImage)
      return null
  }

  return tipCmp({
      inputId = key
      text = ::loc($"controls/{key}")
      font = Fonts.small_text
      style = {rendObj = null}
      animations = animations
    })
}

return function() {
  local res = { watch = defWatches}
  if (!inGroundVehicle.value)
    return res
  res.watch = fullWatches
  local tips = isDriver.value ? DRIVER_TIPS : PASSENGER_TIPS
  local children = showTip.value ? tips.filter(@(key) watches[key].value).map(@(key) prepareTipCmp(key)): null
  return res.__update({
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children = children
    rendObj = ROBJ_WORLD_BLUR_PANEL
  })
}
 