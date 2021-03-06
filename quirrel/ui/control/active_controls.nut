local {set_actions_binding_column_active} = require("dainput2")
local ipc_hub = require("ui/ipc_hub.nut")
local platform = require("globals/platform.nut")
local controlsTypes = require("controls_types.nut")
local forcedControlsType = persist("forcedControlsType", @() Watched(null))
local defRaw = platform.is_pc ? 0 : 1
local lastActiveControlsTypeRaw = persist("lastActiveControlsTypeRaw",@() Watched(defRaw))
local def = platform.is_pc ? controlsTypes.keyboardAndMouse
          : platform.is_sony ? controlsTypes.ds4gamepad
          : platform.is_nswitch ? controlsTypes.nxJoycon
          : platform.is_android ? controlsTypes.touch
          : controlsTypes.x1gamepad

local lastActiveControlsType = persist("lastActiveControlType", @() Watched(def))
console.register_command(@(val) forcedControlsType(val),
  "ui.debugControlsType")

local function update_input_types(msg){
  local map = {
    [1] = controlsTypes.keyboardAndMouse,
    [2] = controlsTypes.x1gamepad,
    //[3] = controlsTypes.ds4gamepad, //< no such value sent
  }
  local ctype = map?[msg?.val] ?? def
  if (platform.is_sony && ctype==controlsTypes.x1gamepad)
    ctype = controlsTypes.ds4gamepad
  else if (platform.is_nswitch)
    ctype = controlsTypes.nxJoycon
  lastActiveControlsTypeRaw.update(msg?.val ?? defRaw)
  lastActiveControlsType.update(ctype)
}

forcedControlsType.subscribe(function(val) {
  if (val)
    update_input_types({val=val})
})

ipc_hub.subscribe("input_dev_used", function(msg) {
  if ([null, 0].indexof(forcedControlsType.value) != null)
    update_input_types(msg)
})

local isGamepad = ::Computed(@() [controlsTypes.x1gamepad,
                                  controlsTypes.ds4gamepad,
                                  controlsTypes.nxJoycon].indexof(lastActiveControlsType.value)!=null )
keepref(isGamepad)

const gamepadColumn = 1
local wasGamepad = persist("wasGamepad", function() {
  local wasGamepadV = platform.is_pc ? false : true
  ::gui_scene.config.gamepadCursorControl = wasGamepadV
  return ::Watched(wasGamepadV)
})
local enabledGamepadControls = Watched(!platform.is_pc || isGamepad.value)
if (platform.is_pc){
  wasGamepad.subscribe(@(v) enabledGamepadControls(v))
  enabledGamepadControls.subscribe(@(v) set_actions_binding_column_active(gamepadColumn, v))
}


isGamepad.subscribe(@(v) wasGamepad(wasGamepad.value || v))
isGamepad.subscribe(@(v) log($"isGamepad changed to = {v}"))

isGamepad.subscribe(@(v) ::gui_scene.config.gamepadCursorControl = v)

return {
  controlsTypes = controlsTypes
  lastActiveControlsType = lastActiveControlsType
  lastActiveControlsTypeRaw = lastActiveControlsTypeRaw
  isGamepad = isGamepad
  wasGamepad = wasGamepad
  enabledGamepadControls = enabledGamepadControls
}
 