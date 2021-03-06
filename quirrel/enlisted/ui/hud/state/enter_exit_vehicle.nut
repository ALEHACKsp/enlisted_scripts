local {EventHeroChanged} = require("gameevents")
local {get_sync_time} = require("net")

local exitVehicleState = persist("exitVehicleState", @() Watched({
  exitStartTime = 0.0
  exitTotalTime = 0.0
}))

local enterVehicleState = persist("enterVehicleState", @() Watched({
  enterStartTime = 0.0
  enterTotalTime = 0.0
}))

local function onExitTimerChanged(evt, eid, comp) {
  local timer = comp["exit_vehicle.atTime"]
  exitVehicleState.update(function (v) {
    v.exitStartTime = get_sync_time()
    v.exitTotalTime = timer >= 0 ? timer - v.exitStartTime : -1.0
  })
}

local function onEnterTimerChanged(evt, eid, comp) {
  local timer = comp["enter_vehicle.atTime"]
  enterVehicleState.update(function (v) {
    v.enterStartTime = get_sync_time()
    v.enterTotalTime = timer >= 0 ? timer - v.enterStartTime : -1.0
  })
}

local function onEndTimers(evt, eid, comp) {
  enterVehicleState.update(@(v) v.enterTotalTime = -1.0)
  exitVehicleState.update(@(v) v.exitTotalTime = -1.0)
}

::ecs.register_es("exit_vehicle_ui_es",
  {
    [["onInit", "onChange"]] = onExitTimerChanged,
    [EventHeroChanged] = onEndTimers
  },
  {
    comps_track = [["exit_vehicle.atTime", ::ecs.TYPE_FLOAT]],
    comps_rq = ["hero"]
  }
)

::ecs.register_es("enter_vehicle_ui_es",
  {
    [["onInit", "onChange"]] = onEnterTimerChanged,
    [EventHeroChanged] = onEndTimers
  },
  {
    comps_track = [["enter_vehicle.atTime", ::ecs.TYPE_FLOAT]],
    comps_rq = ["hero"]
  }
)

return {
  enterVehicleState = enterVehicleState
  exitVehicleState = exitVehicleState
} 