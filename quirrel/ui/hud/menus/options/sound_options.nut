local {get_setting_by_blk_path} = require("settings")
local {sound_set_volume} = require_optional("sound")
local {is_pc} = require("globals/platform.nut")
local {outputDevicesList, outputDevice} = require("globals/sound_state.nut")

local {getOnlineSaveData, optionSlider, optionCombo} = require("options_lib.nut")

local function optionVolSliderCtor(opt, group, xmbNode) {
  local optSetValue = opt.setValue // saved original reference to avoid recursive call of opt.setValue
  local function setValue(val) {
    optSetValue(val)
    sound_set_volume(opt.busName, val)
  }

  opt = opt.__merge({min = 0 max = 1 unit = 0.05 pageScroll = 0.05 setValue = setValue })

  return optionSlider(opt, group, xmbNode)
}

local function soundOption(title, field) {
  local blkPath = $"sound/volume/{field}"
  local { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? 1.0)
  return {
    name = title
    tab = "Sound"
    widgetCtor = optionVolSliderCtor
    var = watch
    setValue = setValue
    defVal = 1.0
    blkPath = blkPath
    busName = field
  }
}
local optVolumeMaster = soundOption(::loc("options/volume_master"), "MASTER")
local optVolumeAmbient = soundOption(::loc("options/volume_ambient"), "ambient")
local optVolumeSfx = soundOption(::loc("options/volume_sfx"), "effects")
local optVolumeInterface = soundOption(::loc("options/volume_interface"), "interface")
local optVolumeMusic = soundOption(::loc("options/volume_music"), "music")
local optVolumeDialogs = soundOption(::loc("options/volume_dialogs"), "voices")
local optVolumeGuns = soundOption(::loc("options/volume_guns"), "weapon")

local optOutputDevice = {
  name = ::loc("options/sound_device_out")
  tab = "Sound"
  widgetCtor = optionCombo
  blkPath = "sound/output_device"
  isAvailable = @() is_pc && outputDevicesList.value.len() > 0
  changeVarOnListUpdate = false
  var = outputDevice
  available = outputDevicesList
  valToString = @(v) v?.name ?? ""
  isEqual = @(a,b) (a?.name ?? "")==(b?.name ?? "")
}

return {
  optVolumeMaster = optVolumeMaster
  optVolumeAmbient = optVolumeAmbient
  optVolumeSfx = optVolumeSfx
  optVolumeInterface = optVolumeInterface
  optVolumeMusic = optVolumeMusic
  optVolumeDialogs = optVolumeDialogs
  optVolumeGuns = optVolumeGuns
  soundOptions = [
    optOutputDevice,
    optVolumeMaster, optVolumeAmbient, optVolumeSfx,
    optVolumeInterface, optVolumeMusic, optVolumeDialogs, optVolumeGuns
  ]
}
 