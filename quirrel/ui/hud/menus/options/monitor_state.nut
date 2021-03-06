
local videomode = require("videomode")

local availableMonitors = videomode.get_available_monitors()

local monitorValue = Watched(availableMonitors.current)

local get_friendly_monitor_name = function(v) {
  local monitor_info = videomode.get_monitor_info(v)
  return monitor_info ? $"{monitor_info[0]} [ #{monitor_info[1] + 1} ]" : v
}

return {
  availableMonitors = availableMonitors
  monitorValue = monitorValue
  get_friendly_monitor_name = get_friendly_monitor_name
} 