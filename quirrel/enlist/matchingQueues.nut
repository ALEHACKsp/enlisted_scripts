local matchingCli = require("matchingClient.nut")
local matching_api = require("matching.api")
local delayedActions = require("utils/delayedActions.nut")
local {get_game_name} = require("app")

local matchingQueuesRaw = persist("matchingQueuesRaw", @() Watched([]))

local function processQueues(val) {
  local curGame = get_game_name()
  local queues = val.filter(@(q) q.game == curGame)
  if (queues.len()==0)
    queues = val
  queues = queues.map(@(queue) {
    id = queue.gameId
    locId = queue?.locId
    modes = queue?.modes
    groupType = queue?.modes?[0].groupType
    extraParams = clone (queue?.extraParams ?? {})
    uiGroup = queue?.extraParams.uiGroup ?? "z"
    uiOrder = queue?.extraParams.uiOrder ?? 1000
    maxGroupSize = queue?.maxGroupSize ?? queue?.modes?[0].groupSize ?? 1
    minGroupSize = queue?.minGroupSize ?? 1
  }.__update(queue))
  queues.sort(@(next, prev)
    next.uiOrder <=> prev.uiOrder
    || next.uiGroup <=> prev.uiGroup
    || next.maxGroupSize <=> prev.maxGroupSize
  )
  return queues
}

local matchingQueues = Computed(@() processQueues(matchingQueuesRaw.value))

local function fetch_matching_queues() {
  local fetchMatchingQueues = fetch_matching_queues
  matchingCli.call("enlmm.get_games_list",
    function(response) {
      debugTableData(response)
      if (!matchingCli.connected.value)
        return
      if (response.error != 0) {
        delayedActions.add(fetchMatchingQueues, 5000)
        return
      }
      delete response.error

      matchingQueuesRaw.update(response.games)
    }, {ver = "2.0"})
}

matchingCli.connected.subscribe(function(state) {
  if (state)
    fetch_matching_queues()
})

local function checkEmptyQueues(){
  if (matchingQueues.value.len()!=0 || !matchingCli.connected)
    return
  fetch_matching_queues()
}

::gui_scene.setInterval(15, checkEmptyQueues) //? TODO: make exponential backoff here

matching_api.subscribe("enlmm.notify_games_list_changed", @(notify) fetch_matching_queues())

return {
  matchingQueues
}
 