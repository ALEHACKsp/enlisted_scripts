local localSettings = require("enlist/options/localSettings.nut")("voice/", false)
local {voiceChatEnabled} = require("voiceChatGlobalState.nut")
local voiceApi = require_optional("voiceApi")
local {settings, modes, activation_modes} = require("globals/voice_settings.nut")
local matchingCli = require("enlist/matchingClient.nut")

local initialized = persist("initialized", @() Watched(false))
local joinedVoiceRooms = persist("joinedVoiceRooms", @() {})

local validation_tbl = {
  chatMode = @(v) modes?[v] ?? settings.chatMode.value
  activationMode = @(v) activation_modes?[v] ?? settings.activationMode.value
}

local validate_setting = @(key, val) validation_tbl?[key](val) ?? val

local function loadVoiceSettings() {
  log("loadVoiceSettings")
  local noop = { // warning disable: -declared-never-used
    recordVolume = localSettings(settings.recordVolume.value, "record_volume")
    playbackVolume = localSettings(settings.playbackVolume.value, "playback_volume")
    chatMode = voiceChatEnabled.value ? localSettings(settings.chatMode.value, "mode") : Watched(modes.off)
    activationMode = localSettings(settings.activationMode.value, "activation_mode")
  }.each(@(watched, key) settings[key].update(validate_setting(key, watched.value)))
}


if (!initialized.value && voiceApi != null) {
  loadVoiceSettings()
  initialized(true)
}

local function leave_voice_chat(voice_chat_id, cb = null) {
  if (voiceApi && voiceChatEnabled.value && voice_chat_id in joinedVoiceRooms) {
    matchingCli.call("mproxy.voice_leave_channel", function(response) {cb?()}, { channel = voice_chat_id })
    voiceApi.leave_room(joinedVoiceRooms[voice_chat_id]?.chanUri ?? "")
    delete joinedVoiceRooms[voice_chat_id]
  }
}

local function join_voice_chat(voice_chat_id) {
  log($"joining voice {voice_chat_id}")
  if (voiceApi && voiceChatEnabled.value && !(voice_chat_id in joinedVoiceRooms)) {
    matchingCli.call("mproxy.voice_join_channel",
                      function(response) {
                        debugTableData(response)
                        if (response.error == 0) {
                          if (!(voice_chat_id in joinedVoiceRooms))
                            return
                          local voiceToken = response?.token
                          local voiceChan = response?.channel
                          local voiceName = response?.name
                          if (voiceToken != null && voiceChan != null && voiceName != null) {
                            log($"join into voice chat as {voiceName} channel: {voiceChan} token: {voiceToken}")
                            voiceApi.join_room(voiceName, voiceToken, voiceChan)
                            joinedVoiceRooms[voice_chat_id].chanUri <- voiceChan
                            return
                          }
                        }
                        log($"failed to join voice channel {voice_chat_id}")
                      },
                      { channel = voice_chat_id })
    joinedVoiceRooms[voice_chat_id] <- {}
  }
}

// Reconnect on connection lost
local function on_room_disconnect(voice_chat_id) {
  if (voice_chat_id in joinedVoiceRooms) {
    log($"reconnect to voice room {voice_chat_id}")
    delete joinedVoiceRooms[voice_chat_id]
    join_voice_chat(voice_chat_id)
  }
}

return {
  leave_voice_chat = leave_voice_chat
  join_voice_chat = join_voice_chat
  on_room_disconnect = on_room_disconnect
  voiceChatEnabled = voiceChatEnabled
}
 