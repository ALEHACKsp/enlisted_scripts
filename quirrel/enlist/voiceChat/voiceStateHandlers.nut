local ipc = require("ipc")
local voiceApi = require_optional("voiceApi")
local voiceState = require("voiceState.nut")
local soundState = require("globals/sound_state.nut")
local {settings, modes, activation_modes} = require("globals/voice_settings.nut")

if (voiceApi == null)
  return null

local function onVoiceChat(new_value) {
  log($"Voice chat mode changed to '{new_value}'")
  if (new_value == modes.off) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(false)
  } else if (new_value == modes.micOff) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(true)
  } else if (new_value == modes.on) {
    voiceApi.enable_mic(true)
    voiceApi.enable_voice(true)
  } else {
    log("Wrong value set for voiceChatMode: ", new_value)
  }
}

local voiceSettingsDescr = {
  recordVolume = {handler = @(val) voiceApi.set_record_volume(val)}
  playbackVolume = {handler = @(val) voiceApi.set_playback_volume(val) }
  recordingEnable = {handler = @(val) voiceApi.set_recording(val) }
  chatMode = {handler=onVoiceChat}
}

soundState.recordDevice.subscribe(function(dev) {
  voiceApi.set_record_device(dev?.id ?? -1)
  settings.recordingEnable.trigger()
})

soundState.recordDevice.trigger()

foreach (k,v in voiceSettingsDescr)
  settings[k].subscribe(v.handler)

// separate loops is essential. do not merge them into one
foreach (k,v in voiceSettingsDescr)
  v.handler(settings[k].value)

local voice_cb = {
  function on_room_connect(chan_uri, success) {
    if (settings.activationMode.value == activation_modes.always)
      settings.recordingEnable(true)
    settings.recordingEnable.trigger()
  }

  function on_room_disconnect(chan_uri) {
    voiceState.on_room_disconnect(chan_uri)
    ipc.send({
      msg = "voice.reset_speaking"
      data = {}
    })
  }

  function on_peer_joined(chan_uri, name) {
  }

  function on_peer_left(chan_uri, name) {
    ipc.send({
      msg = "voice.stop_speaking"
      data = {
        name = name
      }
    })
  }

  function on_peer_start_speaking(chan_uri, name) {
    if (settings.chatMode.value != modes.off) {
      ipc.send({
        msg = "voice.start_speaking"
        data = {
          name = name
        }
      })
    }
  }

  function on_peer_stop_speaking(chan_uri, name) {
    ipc.send({
      msg = "voice.stop_speaking"
      data = {
        name = name
      }
    })
  }
}

voiceApi.set_callbacks(voice_cb)

settings.activationMode.subscribe(function(value) {
  if (value == activation_modes.always)
    settings.recordingEnable(true)
})

local function voice_start_test() {
  voiceApi.join_echo_room()
  settings.recordingEnable.update(true)
}

local function voice_stop_test() {
  voiceApi.leave_echo_room()
  settings.recordingEnable.update(false)
}

local function mute_player(player_name) {
  voiceApi.mute_player_by_name(player_name)
}

local function unmute_player(player_name) {
  voiceApi.unmute_player_by_name(player_name)
}

console.register_command(@(name) voice_cb.on_peer_start_speaking(name),
                          "voice.fake_start_speaking")
console.register_command(@(name) voice_cb.on_peer_stop_speaking(name),
                          "voice.fake_stop_speaking")
console.register_command(voice_start_test, "voice.start_test")
console.register_command(voice_stop_test, "voice.stop_test")
console.register_command(mute_player, "voice.mute_player")
console.register_command(unmute_player, "voice.unmute_player")
 