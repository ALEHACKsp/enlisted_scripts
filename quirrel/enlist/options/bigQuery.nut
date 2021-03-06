local json = require("json")
local { add_bigquery_record, send_to_server } = require("onlineStorage")
local { startSendToSrvTimer, sendToServer } = require("onlineSettings.nut")
local userInfo = require("enlist/state/userInfo.nut")

local isInstantSendToServer = persist("isInstantSend", @() ::Watched(false))
local alreadySend = persist("alreadySend" , @() ::Watched({}))

local sendRecordToServer = @() isInstantSendToServer.value ? send_to_server() : startSendToSrvTimer()

userInfo.subscribe(function(uInfo) {
  if (uInfo == null)
    alreadySend(@(v) v.clear())
})

local wrapToString = @(val) typeof val == "string" ? val : json.to_string(val, false)

local function sendOncePerSession(event, params = null, uid = null) {
  uid = uid ?? event
  if (uid in alreadySend.value)
    return
  alreadySend[uid] <- true
  add_bigquery_record(event, wrapToString(params ?? ""))
  sendRecordToServer()
}

local function sendEvent(event, params = null) {
  add_bigquery_record(event, wrapToString(params ?? ""))
  sendRecordToServer()
}

console.register_command(
  function() {
    sendToServer()
    isInstantSendToServer(!isInstantSendToServer.value)
    ::log("isInstantSendToServer = ", isInstantSendToServer.value)
  },
  "bigQuery.instantSend")

return {
  bqSendOncePerSession = sendOncePerSession
  bqSendEvent = sendEvent
} 