local {settings, activation_modes} = require("globals/voice_settings.nut")
local {activationMode, recordingEnable} = settings

return {
  eventHandlers = {
    ["VoiceChat.Record"] = function(event) {
      if (activationMode.value == activation_modes.pushToTalk)
        recordingEnable(true)
      else if (activationMode.value == activation_modes.toggle)
        recordingEnable(!recordingEnable.value)
    },
    ["VoiceChat.Record:end"] = function(event) {
      if (activationMode.value == activation_modes.pushToTalk)
        recordingEnable(false)
    }
  }
}
 