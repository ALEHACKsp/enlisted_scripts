local {get_time_msec} = require("dagor.time")
local {get_sync_time} = require("net")
local math = require("math")

const defaultTimeStep = 0.016666
local function mkCountdownTimer(endTimeWatch, curTimeFunc=get_sync_time, step = defaultTimeStep, timeProcess = @(v) v) {
  local countdownTimer = ::Watched(0)
  local function updateTimer() {
    local cTime = curTimeFunc()
    local leftTime = ::max((endTimeWatch.value ?? cTime) - cTime, 0)
    if (leftTime > 0) {
      ::gui_scene.clearTimer(updateTimer)
      ::gui_scene.setTimeout(step, updateTimer)
    }
    countdownTimer(timeProcess(leftTime))
  }
  endTimeWatch.subscribe(@(v) updateTimer())
  updateTimer()
  return countdownTimer
}

local function mkUpdateCb(updateDtFunc){
  local curtime = 0
  local last_time = 0
  local function updateCb(){
    curtime = get_time_msec()/1000.0
    updateDtFunc(curtime - last_time)
    last_time = curtime
  }
  return updateCb
}

local setIntervalForUpdateFunc = @(interval, updateDtFunc) ::gui_scene.setInterval(interval, mkUpdateCb(updateDtFunc))

return {
  mkCountdownTimer = mkCountdownTimer
  mkCountdownTimerPerSec = @(endTimeWatch) mkCountdownTimer(endTimeWatch, get_sync_time, 1.0, @(v) math.ceil(v).tointeger())
  mkUpdateCb = mkUpdateCb
  setIntervalForUpdateFunc = setIntervalForUpdateFunc
} 