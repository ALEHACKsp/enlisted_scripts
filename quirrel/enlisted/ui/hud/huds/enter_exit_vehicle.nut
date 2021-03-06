local {enterVehicleState, exitVehicleState} = require("enlisted/ui/hud/state/enter_exit_vehicle.nut")
local indicatorCtor = require("enlisted/ui/hud/huds/vehicle_change_indicator.nut")

local enterTotalTime = ::Computed(@() enterVehicleState.value?.enterTotalTime ?? 0.0)
local enterStartTime = ::Computed(@() enterVehicleState.value?.enterStartTime ?? 0.0)
local enterEndTime = ::Computed(@() enterStartTime.value + enterTotalTime.value)

local exitTotalTime = ::Computed(@() exitVehicleState.value?.exitTotalTime ?? 0.0)
local exitStartTime = ::Computed(@() exitVehicleState.value?.exitStartTime ?? 0.0)
local exitEndTime = ::Computed(@() exitStartTime.value + exitTotalTime.value)

return {
  enterVehicleIndicator = indicatorCtor(enterEndTime, enterTotalTime)
  exitVehicleIndicator = indicatorCtor(exitEndTime, exitTotalTime)
} 