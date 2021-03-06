local {optionCombo, optionSlider} = require("options_lib.nut")
local platform = require("globals/platform.nut")
local voice = require("globals/voice_settings.nut")
local soundState = require("globals/sound_state.nut")
local voiceSettings = voice.settings
local voiceModes = voice.modes
local voiceActivationModes = voice.activation_modes
local {voiceChatEnabled} = require("enlist/voiceChat/voiceChatGlobalState.nut")

local optPlaybackVolume = {
  name = ::loc("voicechat/playback_volume")
  tab = "VoiceChat"
  widgetCtor = optionSlider
  blkPath = "voice/playback_volume"
  defVal = 1.0
  min = 0 max = 1 unit = 0.05 pageScroll = 0.05
  var = voiceSettings.playbackVolume
  originalVal = voiceSettings.playbackVolume.value
  restart = false
  isAvailable = @() voiceChatEnabled.value
}

local optMicVolume = {
  name = ::loc("voicechat/mic_volume")
  tab = "VoiceChat"
  widgetCtor = optionSlider
  blkPath = "voice/record_volume"
  defVal = 1.0
  min = 0 max = 1 unit = 0.05 pageScroll = 0.05
  var = voiceSettings.recordVolume
  originalVal = voiceSettings.recordVolume.value
  restart = false
  isAvailable = @() voiceChatEnabled.value
}

local optMode = {
  name = ::loc("voicechat/mode")
  tab = "VoiceChat"
  widgetCtor = optionCombo
  blkPath = "voice/mode"
  defVal = voiceSettings.chatMode.value
  var = voiceSettings.chatMode
  originalVal = voiceSettings.chatMode.value
  restart = false
  available = voiceModes.keys()
  valToString = @(v) ::loc($"voicechat/{v}")
  isEqual = @(a,b) a==b
  isAvailable = @() voiceChatEnabled.value
}

local optActivationMode = {
  name = ::loc("voicechat/activation_mode")
  tab = "VoiceChat"
  widgetCtor = optionCombo
  blkPath = "voice/activation_mode"
  defVal = voiceSettings.activationMode.value
  var = voiceSettings.activationMode
  originalVal = voiceSettings.activationMode.value
  restart = false
  available = voiceActivationModes.keys()
  valToString = @(v) ::loc($"voicechat/{v}")
  isEqual = @(a,b) a==b
  isAvailable = @() voiceChatEnabled.value && platform.is_pc
}

local optRecordDevice = {
  name = ::loc("voicechat/record_device")
  tab = "VoiceChat"
  widgetCtor = optionCombo
  blkPath = "sound/record_device"
  isAvailable = @() platform.is_pc && voiceChatEnabled.value &&
                    soundState.recordDevicesList.value.len() > 0
  var = soundState.recordDevice
  available = soundState.recordDevicesList
  valToString = @(v) v?.name ?? ""
  isEqual = @(a,b) (a?.name ?? "")==(b?.name ?? "")
  changeVarOnListUpdate = false
}

return {
  optPlaybackVolume = optPlaybackVolume
  optRecordDevice = optRecordDevice
  optActivationMode = optActivationMode
  optMode = optMode
  optMicVolume = optMicVolume

  voiceChatOptions = [
    optPlaybackVolume, optRecordDevice, optActivationMode, optMode, optMicVolume
  ]
}
 