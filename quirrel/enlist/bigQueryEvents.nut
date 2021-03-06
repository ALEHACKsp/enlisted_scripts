local { bqSendEvent } = require("options/bigQuery.nut")

local debugBigQuery = persist("debugBigQuery", @() Watched(false))

local internalSend = @(event, params)
  debugBigQuery.value ? console_print($"bqSendEvent {event}", params) : bqSendEvent(event, params)

local function sendBigQueryUIEvent(eventType, srcWindow = null, srcComponent = null) {
  local params = { }
  if (srcWindow != null)
    params.source_window <- srcWindow
  if (srcComponent != null)
    params.source_component  <- srcComponent
  internalSend(eventType, params)
}

console.register_command(function() {
  local isDebug = !debugBigQuery.value
  console_print($"bqSendEvent debugging is {isDebug ? "ON" : "OFF"}")
  debugBigQuery(isDebug)
}, "debug.bqSendEvent_toggle")

return {
  sendBigQueryUIEvent
} 