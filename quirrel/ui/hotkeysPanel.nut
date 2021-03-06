local {lerp} = require("std/math.nut")
local string = require("string")
local {lastActiveControlsType, isGamepad} = require("ui/control/active_controls.nut")
local controllerType = require("ui/control/controller_type.nut")
local controlsTypes = require("ui/control/controls_types.nut")
local gamepadImgByKey = require("ui/components/gamepadImgByKey.nut")
local navState = Watched([])
local colors = require("ui/style/colors.nut")
local JB = require("ui/control/gui_buttons.nut")
local {verPadding, horPadding, safeAreaAmount} = require("globals/safeArea.nut")
local hotkeysPanelStateComps = require("hotkeysPanelStateComps.nut")
local fakedWorldBlur = require("globals/platform.nut").is_nswitch
local {cursorPresent, cursorOverScroll, config, cursorOverClickable} = ::gui_scene
local text_font = Fonts.small_text
local panel_ver_padding = sh(1)

local function mktext(text){
  return {
    rendObj = ROBJ_DTEXT
    text = text
    color = colors.BtnTextNormal
    font=text_font
  }
}

local defaultJoyAHint = ::loc("ui/cursor.activate")

::gui_scene.setHotkeysNavHandler(function(state) {
  navState(state)
})

local padding = hdpx(5)
local height = ::calc_comp_size({rendObj = ROBJ_DTEXT text = "A" font=text_font})[1].tointeger()

local mkRendObjStyle = @() fakedWorldBlur ? null : ROBJ_WORLD_BLUR_PANEL
local function mkNavBtn(params = {hotkey=null, gamepad=true}){
  local description = params?.hotkey?.description
  local skip = description?.skip
  if (skip)
    return null
  local btnNames = params?.hotkey.btnName ?? []
  local children = params?.gamepad
       ? btnNames.map(@(btnName) gamepadImgByKey.mkImageCompByDargKey(btnName, {height=height}))
       : btnNames.map(@(btnName) {rendObj = ROBJ_DTEXT text = btnName })

  if (type(description)=="string")
    children.append(mktext(description))

  return {
    size = [SIZE_TO_CONTENT, height]
    gap = sh(0.5)
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = children
    padding = hdpx(5)
  }.__merge({ rendObj = mkRendObjStyle() })
}

local function combine_func(a, b){
  return (a.action==b.action)
}

local isActivateKey = @(key) JB.A == key.btnName

local function combine_hotkeys(data, filter_func){
  local ret = []
  foreach (k in data) {
    if (!filter_func(k) || isActivateKey(k))
      continue
    local t = clone k
    local key_used = false
    foreach (i,r in ret) {
      if (combine_func(r,t)) {
        r.btnName.append(t.btnName)
        key_used = true
        break
      }
    }
    if (!key_used) {
      t.btnName = [t.btnName]
      ret.append(t)
    }
  }
  return ret
}

local function getJoyAHintText(data, filter_func) {
  local hotkeyAText = defaultJoyAHint
  foreach (k in data)
    if (filter_func(k) && isActivateKey(k)) {
      if (typeof k?.description == "string")
        hotkeyAText = k.description
      else if (k?.description?.skip)
        hotkeyAText = null
    }
  return hotkeyAText
}


local function _filter(hotkey, devid){
  local descrExist = "description" in hotkey
  return devid.indexof(hotkey.devId) != null && (!descrExist || hotkey.description != null)
}

local showKbdHotkeys = false

local function makeFilterFunc(is_gamepad) {
  return is_gamepad
    ? @(hotkey) _filter(hotkey, [DEVID_JOYSTICK])
    : @(hotkey) showKbdHotkeys && _filter(hotkey, [DEVID_KEYBOARD, DEVID_MOUSE])
}

local filtered_hotkeys = ::Computed(function(){
  return combine_hotkeys(navState.value, makeFilterFunc(isGamepad.value))
})


local joyAHint = ::Computed(function() {
  return getJoyAHintText(navState.value, makeFilterFunc(isGamepad.value))
})

local function svgImg(image){
  local h = gamepadImgByKey.getBtnImageHeight(image, height)
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = ::Picture("!ui/skin#{0}.svg:{1}:{1}:K".subst(image, h.tointeger()))
    keepAspect = true
    size = [h, h]
  }
}
local function manualHint(images, text=""){
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = sh(0.5)
    children = images.map(@(image) svgImg(image)).append(mktext(text))
    padding = padding
  }.__merge({ rendObj = mkRendObjStyle() })
}

local function gamepadcursornav_images(cType){
  switch (controllerType) {
    case controlsTypes.ds4gamepad: return ["ds4/lstick_4" "ds4/dpad"]
    case controlsTypes.nxJoycon: return ["nswitch/lstick_4" "nswitch/dpad"]
  }
  return ["x1/lstick_4" "x1/dpad"]
}

local function gamepadcursorclick_image() {
  local clickButtons = config.getClickButtons()
  return clickButtons
    .filter(@(btn) string.startswith(btn, "J:"))
    .map(@(btn) gamepadImgByKey.keysImagesMap?[btn])
}

local clickHint = manualHint(gamepadcursorclick_image(), joyAHint.value)
local clickHintStub = {size = [::calc_comp_size(clickHint)[0], 0]}
local navigationHint = manualHint(gamepadcursornav_images(lastActiveControlsType.value),::loc("ui/cursor.navigation"))
local scrollHint = manualHint([gamepadImgByKey.keysImagesMap?["J:R.Thumb.hv"]], ::loc("ui/cursor.scroll"))
local function gamepadCursor() {
  return {
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_LEFT
    gap = sh(2.5)
    size = [SIZE_TO_CONTENT, height]
    valign = ALIGN_CENTER
    zOrder = Layers.MsgBox
    watch = [joyAHint, lastActiveControlsType, cursorOverScroll, cursorOverClickable]
    children = [
      navigationHint
      cursorOverClickable.value && joyAHint.value ? clickHint : clickHintStub
      cursorOverScroll.value ? scrollHint : null
      {size = [sh(6),0]}
    ]
  }
}

local show_tips = ::Computed( @()(cursorPresent.value && isGamepad.value) && filtered_hotkeys.value.len()>0 )

local function tipsC(){
  local tips = (cursorPresent.value && isGamepad.value) ? [ gamepadCursor] : []
  tips.extend(filtered_hotkeys.value.map(@(hotkey) mkNavBtn({hotkey=hotkey, gamepad=isGamepad.value})))//.append({size=flex()})
  tips.extend(hotkeysPanelStateComps.value.values())
  return {
    gap = sh(2.5)
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    watch = [filtered_hotkeys, isGamepad, cursorPresent, hotkeysPanelStateComps]
    zOrder = Layers.MsgBox
    children = tips
  }
}
local calc_bottom_margin_mul = @(v) lerp(0.9, 1.0, 0.75, 1,v)
local hotkeysButtonsBarStyle = @() fakedWorldBlur ? {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = colors.HeaderOverlay
  size = [pw(100), height + panel_ver_padding * 2 + calc_bottom_margin_mul(safeAreaAmount.value)*verPadding.value] } : {
  rendObj = null
  fillColor = null
  size = [SIZE_TO_CONTENT, height + panel_ver_padding * 2 + calc_bottom_margin_mul(safeAreaAmount.value)*verPadding.value]
}
local function hotkeysButtonsBar() {
  return show_tips.value ? {
    vplace = ALIGN_BOTTOM
    padding = [panel_ver_padding,sh(4),panel_ver_padding,max(sh(5), horPadding.value)]
    watch = [show_tips, safeAreaAmount, verPadding, horPadding]
    children = tipsC
  }.__merge(hotkeysButtonsBarStyle()) : {watch = show_tips}
}

return hotkeysButtonsBar 