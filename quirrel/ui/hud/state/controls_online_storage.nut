local platform = require("globals/platform.nut")
local platform_id = platform.id
local mkOnlineSaveData = require("enlist/options/mkOnlineSaveData.nut")
local dainput = require("dainput2")
local { logerr } = require("dagor.debug")
local { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")

/*ATTENTION!
  here are onlineSharedOption! They are not supposed to work until login!
  this meant that they are not also correct on login page
  and also with disableMenu
  Fix it somehow later
    probably - save it in separate block on change in game_settings and they should be rewrited by online settings
*/

local clickRumbleSettingId = "input/clickRumbleEnabled"
local uiClickRumbleSave = mkOnlineSaveData(clickRumbleSettingId,
  @() get_setting_by_blk_path(clickRumbleSettingId) ?? ::gui_scene.config.clickRumbleEnabled)

local isUiClickRumbleEnabled = uiClickRumbleSave.watch
::gui_scene.config.clickRumbleEnabled = isUiClickRumbleEnabled.value
local setUiClickRumble = uiClickRumbleSave.setValue
isUiClickRumbleEnabled.subscribe(function(val) {
  ::gui_scene.config.clickRumbleEnabled = val
  set_setting_by_blk_path(clickRumbleSettingId, val)
  save_settings()
})

local inBattleRumbleSettingId = "input/inBattleRumbleEnabled"
local inBattleRumbleSave = mkOnlineSaveData(inBattleRumbleSettingId, @() get_setting_by_blk_path(inBattleRumbleSettingId) ?? true)

local isInBattleRumbleEnabled = inBattleRumbleSave.watch
local setInBattleRumble = inBattleRumbleSave.setValue
isInBattleRumbleEnabled.subscribe(function(val) {
  set_setting_by_blk_path(inBattleRumbleSettingId, val)
  save_settings()
})

local isAimAssistExists = platform.is_xbox || platform.is_sony || platform.is_nswitch
local aimAssistSave = mkOnlineSaveData("game/aimAssist", @() isAimAssistExists, @(v) v && isAimAssistExists)
local isAimAssistEnabled = aimAssistSave.watch
local setAimAssist = isAimAssistExists ? aimAssistSave.setValue
  : @(v) logerr("Try to change aim assist while it not enabled")

local defaultDz = platform.is_sony ? 0.1 : 0.2 //PS4 have better and more calibrated gamepads
local validateDz = @(v) ::clamp(v, 0.0, 0.4)
const gamepadCursorDeadZoneMin = 0.15
local function setGamepadCursorDz(stick_dz){
  local target_dz = gamepadCursorDeadZoneMin
  if (stick_dz > 0)
    target_dz =  stick_dz<1 ? ::clamp((gamepadCursorDeadZoneMin - stick_dz) / (1 - stick_dz), 0.01, 0.3) : 0.3
  ::gui_scene.config.gamepadCursorDeadZone = target_dz
  log("set gamepadCursorDeadZone to: ", target_dz,".Current dz in driver for stick:", stick_dz)
}

local stick0Save = mkOnlineSaveData($"controls/{platform_id}/stick0_dz_ver2", @() defaultDz, validateDz)
local stick0_dz = stick0Save.watch
stick0_dz.subscribe(function(stick_dz) {
  dainput.set_main_gamepad_stick_dead_zone(0, stick_dz)
  if (::gui_scene.config.gamepadCursorAxisH == 0 || ::gui_scene.config.gamepadCursorAxisV == 1)
    setGamepadCursorDz(stick_dz)
})
stick0_dz.trigger()//to cause it's applying

local stick1Save = mkOnlineSaveData($"controls/{platform_id}/stick1_dz_ver2", @() defaultDz, validateDz)
local stick1_dz = stick1Save.watch
stick1_dz.subscribe(function(stick_dz) {
  dainput.set_main_gamepad_stick_dead_zone(1, stick_dz)
  if (::gui_scene.config.gamepadCursorAxisH == 2 || ::gui_scene.config.gamepadCursorAxisV == 3)
    setGamepadCursorDz(stick_dz)
})
stick1_dz.trigger()//to cause it's applying

local validateAimSmooth = @(v) ::clamp(v, 0.0, 0.5)
local aimSmoothSave = mkOnlineSaveData("game/aimSmooth", @() 0.25, validateAimSmooth)

local onlineControls = {
  setUiClickRumble = setUiClickRumble
  isUiClickRumbleEnabled = isUiClickRumbleEnabled

  setInBattleRumble = setInBattleRumble
  isInBattleRumbleEnabled = isInBattleRumbleEnabled

  isAimAssistExists = isAimAssistExists
  isAimAssistEnabled = isAimAssistEnabled
  setAimAssist = setAimAssist
  stick0_dz = stick0_dz
  set_stick0_dz = stick0Save.setValue
  stick1_dz = stick1_dz
  set_stick1_dz = stick1Save.setValue
  aim_smooth = aimSmoothSave.watch
  aim_smooth_set = aimSmoothSave.setValue
}

return onlineControls

 