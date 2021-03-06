local vehicleState = require("ui/hud/state/vehicle_seats.nut")
local indicatorCtor = require("enlisted/ui/hud/huds/vehicle_change_indicator.nut")

local totalTime = ::Computed(@() vehicleState.value.switchSeatsTotalTime ?? 0.0)
local startTime = ::Computed(@() vehicleState.value.switchSeatsTime ?? 0.0)
local endTime = ::Computed(@() startTime.value + vehicleState.value.switchSeatsTotalTime)

return indicatorCtor(endTime, totalTime) 