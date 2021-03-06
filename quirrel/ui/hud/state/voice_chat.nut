local ipc_hub = require("ui/ipc_hub.nut")

local speakingPlayers = persist("speakingPlayers", @() ::Watched({}))
local order = persist("order", @() { val = 0 })

local function onSpeakingStatus(who, is_speaking) {
  if (is_speaking) {
    if (who in speakingPlayers.value)
      return
    speakingPlayers.value[who] <- order.val++
  }
  else {
    if (!(who in speakingPlayers.value))
      return
    delete speakingPlayers.value[who]
  }
  speakingPlayers.trigger()
}

ipc_hub.subscribe("voice.start_speaking", @(msg) onSpeakingStatus(msg.data.name, true))
ipc_hub.subscribe("voice.stop_speaking",  @(msg) onSpeakingStatus(msg.data.name, false))
ipc_hub.subscribe("voice.reset_speaking",  @(msg) speakingPlayers({}))

console.register_command(@(name, state) onSpeakingStatus(name, state),
                         $"voice.display_speaking_player_{::VM_NAME}")

return speakingPlayers
 