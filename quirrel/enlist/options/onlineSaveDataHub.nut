local ipc_hub = require("ui/ipc_hub.nut")
local {logerr} = require("dagor.debug")
local { onlineSettingUpdated, settings } = require("onlineSettings.nut")

local lastValues = {}

local sendValue = @(saveId) ipc_hub.send({ msg = $"onlineData.changed.{saveId}", value = lastValues[saveId] })

local getCurValue = @(saveId) onlineSettingUpdated.value ? settings.value?[saveId] : null

ipc_hub.subscribe("onlineData.init", function(msg) {
  local saveId = msg.saveId
  lastValues[saveId] <- getCurValue(saveId)
  sendValue(saveId)
})

local function onChange(_) {
  foreach(saveId, value in lastValues) {
    local newValue = getCurValue(saveId)
    if (newValue == value)
      continue
    lastValues[saveId] = newValue
    sendValue(saveId)
  }
}
onlineSettingUpdated.subscribe(onChange)
settings.subscribe(onChange)

ipc_hub.subscribe("onlineData.setValue", function(msg) {
  if (!onlineSettingUpdated.value) {
    logerr($"onlineSaveDataHub: try to set value to {msg.saveId} whlie online options not inited")
    return
  }
  local { saveId, value } = msg
  if (lastValues?[saveId] != value)
    settings(function(s) { s[saveId] <- value })
})
 