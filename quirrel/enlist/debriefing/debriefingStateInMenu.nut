local ipc_hub = require("ui/ipc_hub.nut")
local { debounce } = require("utils/timers.nut")
local battleResultUserstats = require("battleResultUserstats.nut") //we can receive new userstats when ui vm already reseted

local data = persist("data", @() Watched(null))
local show = persist("show", @() Watched(false))

ipc_hub.subscribe("debriefing.data", @(msg) data(msg.data))
ipc_hub.subscribe("debriefing.show", @(msg) show(msg.show))

local computedData = ::Computed(function() {
  local baseData = data.value
  if (baseData == null)
    return baseData

  local stats = battleResultUserstats.value?[baseData?.sessionId]
  return stats != null ? baseData.__merge({ userstats = stats }) : baseData
})

local clearLastUserstat = debounce(function(sessionId) {
  if (sessionId in battleResultUserstats.value)
    delete battleResultUserstats.value[sessionId] //no need to trigger here
}, 0.1)
local lastSessionId = null
data.subscribe(function(d) {
  local sessionId = d?.sessionId
  if (sessionId == null || sessionId == lastSessionId)
    return
  clearLastUserstat(lastSessionId)
  lastSessionId = sessionId
})

local clearData = @() data(null)

return {
  show = show
  data = computedData
  clearData = clearData
} 