local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local style = require("ui/hud/style.nut")
local {vehicleRepairTime, inVehicle} = require("ui/hud/state/vehicle_state.nut")
local {mkCountdownTimer} = require("ui/helpers/timers.nut")

local {secondsToTimeSimpleString} = require("utils/time.nut")

local repairTimer = mkCountdownTimer(vehicleRepairTime)
return function () {
  local tip = null
  if (inVehicle.value && vehicleRepairTime.value > 0) {
    tip = tipCmp({
      text = ::loc("hud/vehicle_repair", "Vehicle repair in progress, {time} left",
        {time = secondsToTimeSimpleString(repairTimer.value)})
      textColor =  style.DEFAULT_TEXT_COLOR
    })
  }

  return {
    watch = [ inVehicle, vehicleRepairTime, repairTimer ]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = tip
  }
} 