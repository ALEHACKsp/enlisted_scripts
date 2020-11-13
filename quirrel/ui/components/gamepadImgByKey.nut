local controlsTypes = require("ui/control/controls_types.nut")
local controllerType = require("ui/control/controller_type.nut")
local dainput = require("dainput2")

local dargJKeys2X1Image = {
  "J:D.Up"          : "dpad_up",
  "J:D.Down"        : "dpad_down",
  "J:D.Left"        : "dpad_left",
  "J:D.Right"       : "dpad_right",
  "J:A"             : "a",
  "J:B"             : "b",
  "J:CROSS"         : "a",
  "J:CIRCLE"        : "b",

  "J:Start"         : "start",
  "J:Menu"          : "start",
  "J:Back"          : "back",
  "J:Select"        : "back",
  "J:View"          : "back",

  "J:L.Thumb"       : "lstick_pressed",
  "J:LS"            : "lstick_pressed",
  "J:L3"            : "lstick_pressed",
  "J:L3.Centered"   : "lstick_pressed",
  "J:LS.Centered"   : "lstick_pressed",
  "J:R.Thumb"       : "rstick_pressed",
  "J:RS"            : "rstick_pressed",
  "J:R3"            : "rstick_pressed",
  "J:R3.Centered"   : "rstick_pressed",
  "J:RS.Centered"   : "rstick_pressed",

  "J:L.Shoulder"    : "lshoulder",
  "J:LB"            : "lshoulder",
  "J:L1"            : "lshoulder",
  "J:R.Shoulder"    : "rshoulder",
  "J:RB"            : "rshoulder",
  "J:R1"            : "rshoulder",

  "J:X"             : "x",
  "J:Y"             : "y",
  "J:SQUARE"        : "x",
  "J:TRIANGLE"      : "y",

  "J:L.Trigger"     : "ltrigger",
  "J:LT"            : "ltrigger",
  "J:L2"            : "ltrigger",
  "J:R.Trigger"     : "rtrigger",
  "J:RT"            : "rtrigger",
  "J:R2"            : "rtrigger",

  "J:L.Thumb.Right" : "lstick_right",
  "J:LS.Right"      : "lstick_right",
  "J:L.Thumb.Left"  : "lstick_left",
  "J:LS.Left"       : "lstick_left",
  "J:L.Thumb.Up"    : "lstick_up",
  "J:LS.Up"         : "lstick_up",
  "J:L.Thumb.Down"  : "lstick_down",
  "J:LS.Down"       : "lstick_down",

  "J:R.Thumb.Right" : "rstick_right",
  "J:RS.Right"      : "rstick_right",
  "J:R.Thumb.Left"  : "rstick_left",
  "J:RS.Left"       : "rstick_left",
  "J:R.Thumb.Up"    : "rstick_up",
  "J:RS.Up"         : "rstick_up",
  "J:R.Thumb.Down"  : "rstick_down",
  "J:RS.Down"       : "rstick_down",

  "J:L.Thumb.h"     : "lstick_x",
  "J:L.Thumb.v"     : "lstick_y",
  "J:R.Thumb.h"     : "rstick_x",
  "J:R.Thumb.v"     : "rstick_y",

  "J:R.Thumb.hv"     : "rstick_4",
  "J:L.Thumb.hv"     : "lstick_4",

  "J:SensorX" : "sensor_x",
  "J:SensorZ" : "sensor_z",
  "J:SensorY" : "sensor_y",
}

/*
local string = require("string")
local kbdImages = ["Alt", "Left Alt", "Right Alt", "Backspace", "Caps Lock", "Ctrl", "Left Ctrl", "Right Ctrl", "Del", "Down", "End", "Enter", "Esc", "Home", "Left", "Num Lock", "Page Down", "Page Up", "Right", "Shift", "Right Shift", "Space", "Tab", "Up" ]
local kbdImagesMap = function(){
  local res = {}
  foreach (k in kbdImages) {
    local v = k.tolower()
    v = "kbd_" + string.split(v, " ").reduce(@(a,b) a+b, "")
    res[k]<-v
  }
  return res
}()
*/

local btnsNum = [ "D.Up", "D.Down", "D.Left", "D.Right", "Start", "Select", "L3", "R3", "L1", "R1", "0x0400", "0x0800", "CROSS", "CIRCLE", "SQUARE", "TRIANGLE", "L2", "R2", "LS.Right", "LS.Left", "LS.Up", "LS.Down", "RS.Right", "RS.Left", "RS.Up", "RS.Down", "L3.Centered", "R3.Centered"]
local axisNum = ["L.Thumb.h", "L.Thumb.v", "R.Thumb.h", "R.Thumb.v", "L.Trigger", "R.Trigger", "R+L.Trigger", "J:SensorX", "J:SensorZ", "J:SensorY"]

local function keyAndImg(table, list, prefix, offs){
  foreach (i, k in list) {
    local key = prefix+(i+offs) //for unknow reasons all indexes are incremented
    local img = dargJKeys2X1Image?[$"J:{k}"]
    if (img)
      table[key] <- img
   }
}
local basicJBtns = {}
keyAndImg(basicJBtns, btnsNum, "J:Button", 1)
keyAndImg(basicJBtns, axisNum, "J:Axis", 1)
keyAndImg(basicJBtns, btnsNum, "J:B", 0)
keyAndImg(basicJBtns, axisNum, "J:A", 0)

local mouseKeyboardImg = {
  "M:X"   : "mouse/mouse_x",
  "M:Y"   : "mouse/mouse_y",
  "M:XY"  : "mouse/mouse_4",
  "M:2"   : "mouse/mmb",
  "M:1"   : "mouse/rmb",
  "M:0"   : "mouse/lmb",
  "MMB"   : "mouse/mmb",
  "LMB"   : "mouse/lmb",
  "RMB"   : "mouse/rmb",
  "MWDown": "mouse/mouse_mwdown",
  "MWUp"  : "mouse/mouse_mwup",
}

local eventTypesImg = {
  [dainput.BTN_pressed_long] = "input_modes/hold",
  [dainput.BTN_pressed2] = "input_modes/doubleclick",
  [dainput.BTN_pressed3] = "input_modes/trippleclick",
  [dainput.BTN_released] = "input_modes/release",
  [dainput.BTN_released_short] = "input_modes/fast_release",
  [dainput.BTN_released_long] = "input_modes/hold_release",
  ["__and__"] = "input_modes/and"
}
/*
local eventTypesImg = {
  "(hold)" : "hold"
  "(release)" : "release"
  "(fast release)" : "fast_release"
  "(hold & release)" : "hold_release"
  "(double click)" : "doubleclick"
  "(tripple click)" : "trippleclick"
}
*/
local sticksAliases = {
  lx = ["J:L.Thumb.h", "J:Axis1"]
  ly = ["J:L.Thumb.v", "J:Axis2"]
  rx = ["J:R.Thumb.h", "J:Axis3"]
  ry = ["J:R.Thumb.v", "J:Axis4"]
}

local dargJKeys2DS4Image = dargJKeys2X1Image.map(@(v) $"ds4/{v}")
local dargJKeysJoyconImage = dargJKeys2X1Image.map(@(v) $"nswitch/{v}")
dargJKeys2X1Image = dargJKeys2X1Image.map(@(v) $"x1/{v}")

local dargJKeysImagesByCType = {
  ds4gamepad = dargJKeys2DS4Image
  x1gamepad = dargJKeys2X1Image
  nxJoycon = dargJKeysJoyconImage
}
local defaultDargJKeysImage = dargJKeys2X1Image
local dargJKeysToImage = @(controller_type) dargJKeysImagesByCType?[controller_type] ?? defaultDargJKeysImage

local updateButtonByCType = {
  ds4gamepad = @(v) $"ds4/{v}"
  x1gamepad = @(v) $"x1/{v}"
  nxJoycon = @(v) $"nswitch/{v}"
}
local defaultButtonUpdate = @(v) $"x1/{v}"
local updateBasicJBtns = @(controller_type, btns) btns.map(updateButtonByCType?[controller_type] ?? defaultButtonUpdate)

local keysImagesMap = mouseKeyboardImg
  .__merge(eventTypesImg)
  .__update(dargJKeysToImage(controllerType))
  .__update(updateBasicJBtns(controllerType, basicJBtns))

local defHeightMul = 1.35 //sticks and dirpad has more images, and they better to be increased size
local heightMuls = {
  ["x1/a"] = 1,
  ["x1/b"] = 1,
  ["x1/x"] = 1,
  ["x1/y"] = 1,
  ["x1/lstick_pressed"] = 1,
  ["x1/rstick_pressed"] = 1,
  ["x1/ltrigger"] = 1,
  ["x1/rtrigger"] = 1,
  ["x1/lshoulder"] = 1.2,
  ["x1/rshoulder"] = 1.2,
  ["ds4/a"] = 1,
  ["ds4/b"] = 1,
  ["ds4/x"] = 1,
  ["ds4/y"] = 1,
  ["ds4/ltrigger"] = 1,
  ["ds4/rtrigger"] = 1,
  ["ds4/lshoulder"] = 1.2,
  ["ds4/rshoulder"] = 1.2,
  ["nswitch/a"] = 1,
  ["nswitch/b"] = 1,
  ["nswitch/x"] = 1,
  ["nswitch/y"] = 1,
  ["nswitch/ltrigger"] = 1,
  ["nswitch/rtrigger"] = 1,
  ["nswitch/lshoulder"] = 1.2,
  ["nswitch/rshoulder"] = 1.2,
  ["nswitch/lstick_pressed"] = 1,
  ["nswitch/rstick_pressed"] = 1,
}

local function getBtnImageHeight(imageName, aHeight) {
  return ((heightMuls?[imageName] ?? defHeightMul) * aHeight).tointeger()
}

local defHeight = ::calc_comp_size({rendObj = ROBJ_DTEXT text="A" font = Fonts.medium_text})[1].tointeger()

local function mkImageComp(text, params = defHeight){
  if (text==null || text=="")
    return null
  if (::type(params) != "table")
    params = {height = params}
  local height = params?.height ?? defHeight
  height = getBtnImageHeight(text, height)
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = ::Picture("ui/skin#{0}.svg:{1}:{1}:K".subst(text, height.tointeger())) // TODO: consider make a cache for pictures
    keepAspect = true
    size = [height, height]
  }.__merge(params)
}


local controlsTypeMap = {
  [controlsTypes.ds4gamepad] = dargJKeys2DS4Image,
  [controlsTypes.x1gamepad] = dargJKeys2X1Image,
  [controlsTypes.keyboardAndMouse] = mouseKeyboardImg,
  [controlsTypes.nxJoycon] = dargJKeysJoyconImage
}

local function mkImageCompByDargKey(key, params={}) {
  local cType = params?.controlsType ?? controllerType
  local gamepadMap = controlsTypeMap?[cType] ?? (dargJKeysToImage(controllerType))
  return (gamepadMap?[key] != null)
    ? mkImageComp(gamepadMap?[key] ?? key, params)
    : {rendObj=ROBJ_FRAME, size = [defHeight, defHeight]}.__merge(params)
}

return {
  mkImageComp = mkImageComp
  dargJKeys2X1Image = dargJKeys2X1Image
  mouseKeyboardImg = mouseKeyboardImg
  dargJKeys2DS4Image = dargJKeys2DS4Image
  dargJKeysJoyconImage = dargJKeysJoyconImage
  mkImageCompByDargKey = mkImageCompByDargKey
  keysImagesMap = keysImagesMap
  getBtnImageHeight = getBtnImageHeight
  sticksAliases = sticksAliases
  defHeight = defHeight
}
 