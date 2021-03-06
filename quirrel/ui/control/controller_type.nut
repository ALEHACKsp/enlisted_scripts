local platform = require("globals/platform.nut")
local controlsTypes = require("controls_types.nut")
local gamepadTypeByPlatform = {
  nswitch = controlsTypes.nxJoycon
  ps4 = controlsTypes.ds4gamepad
}
return gamepadTypeByPlatform?[platform.id] ?? controlsTypes.x1gamepad 