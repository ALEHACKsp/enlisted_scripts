local {get_setting_by_blk_path} = require("settings")
local platform = require("globals/platform.nut")
local sharedWatched = require("globals/sharedWatched.nut")

local modes = {
  on = "on"
  off = "off"
  micOff = "micOff"
}

local activation_modes = {
  toggle = "toggle"
  pushToTalk = "pushToTalk"
  always = "always"
}

local validateMode = @(mode, list, defValue) mode in list ? mode : defValue

local settings = {
  recordVolume = ::clamp(get_setting_by_blk_path("voice/record_volume") ?? 1.0, 0.0, 1.0)
  playbackVolume = ::clamp(get_setting_by_blk_path("voice/playback_volume") ?? 1.0, 0.0, 1.0)
  recordingEnable = false
  chatMode = validateMode(get_setting_by_blk_path("voice/mode"), modes, modes.on)
  activationMode = validateMode(get_setting_by_blk_path("voice/activation_mode"),
    activation_modes,
    platform.is_pc ? activation_modes.toggle : activation_modes.always)
}.map(@(value, name) sharedWatched($"voiceState.{name}", @() value))

return {
  settings = settings
  modes = modes
  activation_modes = activation_modes
}
 