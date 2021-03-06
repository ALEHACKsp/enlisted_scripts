  

                                       

                                                                                   

                                                                          

  

local get_time_msec = require("dagor.time").get_time_msec
local workcycle = require("dagor.workcycle")

local delayedActionsList = persist("delayedActionsList", @() [])
local instantActionsList = persist("instantActionsList", @() [])

local function runDelayedActions() {
  if (delayedActionsList.len() == 0)
    return

  local curTime = get_time_msec()
  local callActions = []

  // actions is sorted by call time from last to first
  for (local i = delayedActionsList.len() - 1; i >= 0; --i) {
    local elem = delayedActionsList[i]
    if (elem.time <= curTime) {
      callActions.append(elem.action)
      delayedActionsList.pop()
    }
    else
      break
  }

  foreach (action in callActions)
    action()
}

local function runInstantActions() {
  if (instantActionsList.len() == 0)
    return

  local actions = instantActionsList
  instantActionsList = []

  foreach (action in actions)
    action()
}

local function addDelayedAction(action, delay_ms) {
  if (delay_ms > 0) {
    local callTime = get_time_msec() + delay_ms
    delayedActionsList.append({action = action, time = callTime})
    delayedActionsList.sort(function (a, b) {
      return (b.time - a.time).tointeger()
    })
  }
  else
    instantActionsList.append(action)
}

workcycle.add_cycle_action("delayedActions.update",
  function() {
    runDelayedActions()
    runInstantActions()
  })

return {
  add = @(action, delay_ms = 0) addDelayedAction(action, delay_ms)
}
 