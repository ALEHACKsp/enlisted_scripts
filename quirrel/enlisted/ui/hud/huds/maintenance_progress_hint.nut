local {useActionAvailable} = require("ui/hud/state/actions_state.nut")
local {maintenanceTime, maintenanceTotalTime} = require("ui/hud/state/vehicle_state.nut")
local {mkCountdownTimer} = require("ui/helpers/timers.nut")
local {ACTION_EXTINGUISH, ACTION_REPAIR} = require("hud_actions")
local fa = require("daRg/components/fontawesome.map.nut")

local maintenanceActions = {
  [ACTION_EXTINGUISH] = { icon = fa["fire-extinguisher"]},
  [ACTION_REPAIR] = { icon = fa["wrench"]},
}

local maintenanceTimer = mkCountdownTimer(maintenanceTime)
local maintenanceProgress = ::Computed(@() maintenanceTotalTime.value > 0 ? (1 - (maintenanceTimer.value / maintenanceTotalTime.value)) : 0)

local commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
local sector = commands[1]
local maintenanceIndicatorSize = [hdpx(80), hdpx(80)]
local maintenanceIndicator = @(action) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_STEXT
      font = Fonts.fontawesome
      color = Color(255, 255, 255)
      text = action.icon
      fontSize = hdpx(40)
    }
    {
      behavior = Behaviors.RtPropUpdate
      size = maintenanceIndicatorSize
      lineWidth = hdpx(6.0)
      color = Color(0, 255, 0)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      commands = commands
      update = function() {
        sector[6] = 360.0 * maintenanceProgress.value
      }
    }
  ]
}

return function () {
  local action = maintenanceActions?[useActionAvailable.value]

  return {
    watch = [maintenanceTime, maintenanceTimer]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = (maintenanceTime.value > 0 && action != null) ? maintenanceIndicator(action) : null
  }
} 