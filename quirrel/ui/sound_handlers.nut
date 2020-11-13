local {get_setting_by_blk_path} = require("settings")
local {outputDevice, outputDevicesList, recordDevice, recordDevicesList} = require("globals/sound_state.nut")

local {startsWith} = require("std/string.nut")
local {sound_set_callbacks, sound_get_output_devices, sound_get_record_devices, sound_set_output_device} = require("sound")

local function findBestOutputDevice(devs_list) {
  return devs_list?[0] // first device in list is a device choosen by system as default
}

local function findBestRecordDevice(devs_list) {
  local filterfunc = function(d) {
    // add various rules here for inapropriate devices for sound recording
    // on different platforms
    return !startsWith(d.name, "Monitor of") // monitor device is a loopback from output in pulseaudio
  }
  local suitable = devs_list.filter(filterfunc)
  return suitable?[0] ?? devs_list?[0]
}

local function get_output_devices() {
  local sysDevs = sound_get_output_devices()
  if (sysDevs.len() > 0)
    return sysDevs
  return [{
    name = "No Output"
    id = -1
  }]
}

local function get_record_devices() {
  local sysDevs = sound_get_record_devices()
  if (sysDevs.len() > 0)
    return sysDevs
  return [{
    name = "No Record"
    id = -1
  }]
}


if (outputDevicesList.value.len() == 0)
  outputDevicesList(get_output_devices())

if (recordDevicesList.value.len() == 0)
  recordDevicesList(get_record_devices())


local function isDeviceInList(dev, devs_list) {
  if (dev == null)
    return false
  foreach (d in devs_list)
    if (d.name == dev?.name && d.id == dev?.id)
      return true
  return false
}

outputDevice.subscribe(function(dev) {
  log($"[sound] set output device {dev?.name}")
  sound_set_output_device(dev ? dev.id: 0)
})

recordDevice.subscribe(function(dev) {
  log($"[sound] set record device {dev?.name}")
})

outputDevicesList.subscribe(function(dlist) {
  log(dlist)
})

recordDevicesList.subscribe(function(dlist) {
  log(dlist)
})

if (outputDevice.value == null) {
  local dev = get_setting_by_blk_path("sound/output_device")
  if (!isDeviceInList(dev, outputDevicesList.value))
    dev = findBestOutputDevice(outputDevicesList.value)
  outputDevice(dev)

}

if (recordDevice.value == null) {
  local dev = get_setting_by_blk_path("sound/record_device")
  if (!isDeviceInList(dev, recordDevicesList.value))
    dev = findBestRecordDevice(recordDevicesList.value)
  recordDevice(dev)
}

sound_set_callbacks({
  function on_record_devices_list_changed() {
    recordDevicesList(get_record_devices())
    if (!isDeviceInList(recordDevice.value, recordDevicesList.value))
      recordDevice(findBestRecordDevice(recordDevicesList.value))
  }

  function on_output_devices_list_changed() {
    outputDevicesList(get_output_devices())
    if (!isDeviceInList(outputDevice.value, outputDevicesList.value))
      outputDevice(findBestOutputDevice(outputDevicesList.value))
  }
})
 