local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local { inPlane, isDriver } = require("ui/hud/state/vehicle_state.nut")
local { mkHasBinding } = require("ui/hud/components/controlHudHint.nut")
local DRIVER_TIPS = ["Human.SeatNext", "Plane.Throttle", "Plane.Ailerons","Plane.Elevator", "plane.Rudder","Plane.EngineToggle", "Plane.ToggleGear"] //"Plane.MouseAimToggle","Plane.InstructorToggle", "Plane.SimpleJoy"
local PASSENGER_TIPS = ["Human.SeatNext"]
local watches = {}
foreach (key in [].extend(DRIVER_TIPS).extend(PASSENGER_TIPS))
  watches[key] <- mkHasBinding(key)

local showTip = Watched(true)
local animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
local defWatches = [inPlane, isDriver]
local fullWatches = [showTip].extend(defWatches).extend(watches.values())

const showTipFor = 15
inPlane.subscribe(@(v) showTip(v))
local hideTip = @() ::gui_scene.setTimeout(showTipFor, @() showTip(false))
showTip.subscribe(function(v) {if(v) hideTip()})
hideTip()

return function() {
  local res = { watch = defWatches}
  if (!inPlane.value)
    return res
  res.watch = fullWatches
  local tips = isDriver.value ? DRIVER_TIPS : PASSENGER_TIPS
  local children = showTip.value ? tips.filter(@(key) watches[key].value).map(@(key) tipCmp({
      inputId = key
      text = ::loc($"controls/{key}")
      font = Fonts.small_text
      style = {rendObj = null}
      animations = animations
    })): null
  return res.__update({
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children = children
    rendObj = ROBJ_WORLD_BLUR_PANEL
  })
}
 