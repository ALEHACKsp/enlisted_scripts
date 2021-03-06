local ipc_hub = require("ui/ipc_hub.nut")
local userInfo = require("enlist/state/userInfo.nut")
local online_storage = require("onlineStorage")

local onlineSettingUpdated = persist("onlineSettingUpdated", @() Watched(false))
local settings = persist("onlineSettings", @() Watched(online_storage.get_table_from_online_storage("GBT_GENERAL_SETTINGS")))

const SEND_PENDING_TIMEOUT_SEC = 600 //10 minutes should be ok

local function onUpdateSettings(userId) {
  local fromOnline = online_storage.get_table_from_online_storage("GBT_GENERAL_SETTINGS")
  settings.update(fromOnline)
  onlineSettingUpdated(true)
}

local isSendToSrvTimerStarted = false

local function sendToServer() {
  if (!isSendToSrvTimerStarted)
    return //when timer not started, than settings already sent

  log("onlineSettings: send to server")
  ::gui_scene.clearTimer(callee())
  isSendToSrvTimerStarted = false
  online_storage.send_to_server()
}

local function startSendToSrvTimer() {
  if (isSendToSrvTimerStarted) {
    log("onlineSettings: timer to send is already on")
    return
  }

  isSendToSrvTimerStarted = true
  log("onlineSettings: start timer to send")
  ::gui_scene.setTimeout(SEND_PENDING_TIMEOUT_SEC, sendToServer)
}

userInfo.subscribe(function (new_val) {
  if (new_val != null)
    return
  sendToServer()
  onlineSettingUpdated(false)
})

settings.subscribe(function(new_val) {
  online_storage.save_table_to_online_storage(new_val, "GBT_GENERAL_SETTINGS")
  startSendToSrvTimer()
})

local function loadFromCloud(userId, cb) {
  online_storage.load_from_cloud(userId, cb)
}

ipc_hub.subscribe("onlineSettings.sendToServer", @(m) sendToServer())

return {
  onUpdateSettings = onUpdateSettings
  onlineSettingUpdated = onlineSettingUpdated
  settings = settings
  loadFromCloud = loadFromCloud
  startSendToSrvTimer = startSendToSrvTimer
  sendToServer = sendToServer
}
 