local {dtext} = require("daRg/components/std.nut")
local {defHeight, sticksAliases,mkImageComp, keysImagesMap} = require("ui/components/gamepadImgByKey.nut")
local {generation} = require("ui/hud/menus/controls_state.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local dainput = require("dainput2")
local format_ctrl_name = dainput.format_ctrl_name

local function mkText(text, params={}){
  if (text==null || text=="")
    return null
  return dtext(::loc(text))
}

local validDevices = [dainput.DEV_kbd, dainput.DEV_pointing, dainput.DEV_gamepad, dainput.DEV_joy]
local function isValidDevice(dev) {
  return validDevices.indexof(dev) != null
}

local ButtonAnd = class{
  function _tostring(){
    return "+"
  }
}
local function buildModifiersList(binding) {
  local res = []
  local mods = binding.mod
  for (local i=0, n=binding.modCnt; i<n; ++i) {
    if (isValidDevice(mods[i].devId)) {
      res.append(format_ctrl_name(mods[i].devId, mods[i].btnId))
      res.append(ButtonAnd())
    }
  }
  return res
}

local inParents = @(locId) "({0})".subst(locId)
local eventTypeMap = {
  [dainput.BTN_pressed] = null,
  [dainput.BTN_pressed_long] = "controls/digital/mode/hold",
  [dainput.BTN_pressed2] = "controls/digital/multiClick/2",
  [dainput.BTN_pressed3] = "controls/digital/multiClick/3",
  [dainput.BTN_released] = "controls/digital/release",
  [dainput.BTN_released_short] = "controls/digital/release_short",
  [dainput.BTN_released_long] = "controls/digital/hold_release"
}

local eventTypeLabels = {
  [dainput.BTN_pressed] = "controls/digital/onPressed",
  [dainput.BTN_pressed_long] = "controls/digital/onHold",
  [dainput.BTN_pressed2] = "controls/digital/multiClick/2",
  [dainput.BTN_pressed3] = "controls/digital/multiClick/3",
  [dainput.BTN_released] = "controls/digital/checkReleased",
  [dainput.BTN_released_short] = "controls/digital/onClick",
  [dainput.BTN_released_long] = "controls/digital/onHoldReleased"
}
local notImportantEventsTexts = [dainput.BTN_released_short, dainput.BTN_released].map(@(v) eventTypeMap[v])

//const inverseTxt = "inverse"
const axesSeparatorTxt = "/"
const axesGroupSeparatorTxt = ";"

local function getSticksText(stickBinding) {
  local b = stickBinding
  local xaxis = format_ctrl_name(b.devId, b.axisXId, false)
  local yaxis = format_ctrl_name(b.devId, b.axisYId, false)
  if (sticksAliases.rx.indexof(xaxis)!=null && sticksAliases.ry.indexof(yaxis)!=null)
    return "J:R.Thumb.hv"
  if (sticksAliases.lx.indexof(xaxis)!=null && sticksAliases.ly.indexof(yaxis)!=null)
    return "J:L.Thumb.hv"
  if (xaxis == "M:X" && yaxis=="M:Y")
    return "M:XY"
  return null
}


local function mkBuildDigitalBindingText(b, eventTypeToText=true) {
  local res = buildModifiersList(b).map(@(v) eventTypeToText? v.tostring() : v)
  res.append(format_ctrl_name(b.devId, b.ctrlId, b.btnCtrl))
  local etype = eventTypeToText ? eventTypeMap?[b.eventType] : b.eventType
  if (etype)
    res.append(etype)
  return res
}
local buildDigitalBindingText = @(b) mkBuildDigitalBindingText(b)

local function textListFromAction(action_name, column, eventTypeToText=true) {
  local ah = dainput.get_action_handle(action_name, 0xFFFF)
  local digitalBinding = dainput.get_digital_action_binding(ah, column)
  local axisBinding = dainput.get_analog_axis_action_binding(ah, column)
  local stickBinding = dainput.get_analog_stick_action_binding(ah, column)

  local res
  if (digitalBinding) {
    res = mkBuildDigitalBindingText(digitalBinding, eventTypeToText)
  }
  else if (axisBinding) {
    local b = axisBinding
    res = buildModifiersList(b)
    if (isValidDevice(b.devId)) {
      local text = format_ctrl_name(b.devId, b.axisId, false)
//      if (b.invAxis)
//        res.append(inverseTxt)
      res.append(text)
    }

    if (dainput.get_action_type(ah) == dainput.TYPE_STEERWHEEL) {
      if (isValidDevice(b.minBtn.devId) || isValidDevice(b.maxBtn.devId)) {
        res.append(format_ctrl_name(b.minBtn.devId, b.minBtn.btnId, true))
        res.append(axesSeparatorTxt)
        res.append(format_ctrl_name(b.maxBtn.devId, b.maxBtn.btnId, true))
      }
    }
    else {
      if (dainput.is_action_stateful(ah)){
        local oneGroupExist = false
        if (isValidDevice(b.incBtn.devId) || isValidDevice(b.decBtn.devId)) {
          res.append(format_ctrl_name(b.decBtn.devId, b.decBtn.btnId, true))
          res.append(axesSeparatorTxt)
          res.append(format_ctrl_name(b.incBtn.devId, b.incBtn.btnId, true))
          oneGroupExist = true
        }
        if (isValidDevice(b.minBtn.devId) || isValidDevice(b.maxBtn.devId)) {
          if (oneGroupExist)
            res.append(axesGroupSeparatorTxt)
          res.append(format_ctrl_name(b.minBtn.devId, b.minBtn.btnId, true))
          res.append(axesSeparatorTxt)
          res.append(format_ctrl_name(b.maxBtn.devId, b.maxBtn.btnId, true))
        }
      }
      else {
        if (isValidDevice(b.maxBtn.devId)) {
          res.append(format_ctrl_name(b.maxBtn.devId, b.maxBtn.btnId, true))
        }
      }
    }
  }
  else if (stickBinding) {
    local b = stickBinding
    res = buildModifiersList(b)
    if (isValidDevice(b.devId)) {
      local sticksText = getSticksText(b)
      if (sticksText != null) {
        res.append(sticksText)
      }
      else {
//        if (b.axisXinv)
//          res.append(inverseTxt)
        res.append(format_ctrl_name(b.devId, b.axisXId, false))

        res.append(axesSeparatorTxt)

//        if (b.axisYinv)
//          res.append(inverseTxt)
        res.append(format_ctrl_name(b.devId, b.axisYId, false))
      }
    }
    if (b.minXBtn.devId)
      res.append(format_ctrl_name(b.minXBtn.devId, b.minXBtn.btnId, true))
    if (b.maxXBtn.devId)
      res.append(format_ctrl_name(b.maxXBtn.devId, b.maxXBtn.btnId, true))
    if (b.minYBtn.devId)
      res.append(format_ctrl_name(b.minYBtn.devId, b.minYBtn.btnId, true))
    if (b.maxYBtn.devId)
      res.append(format_ctrl_name(b.maxYBtn.devId, b.maxYBtn.btnId, true))
  }
  else
    res = []
  return res
}
local controlImagesList = keysImagesMap.values()
local eventTypeValues = eventTypeMap.values()

local function buildElems(textlist, params = {imgFunc=null, textFunc=mkText, eventTextFunc = null, eventTypesAsTxt=false, compact=false}){
  local makeImg = params?.imgFunc ?? mkImageComp
  local textFunc = params?.textFunc ?? mkText
  local eventTextFunc = params?.eventTextFunc ?? textFunc
  local eventTypesAsTxt = params?.eventTypesAsTxt ?? false
  local compact = params?.compact
  if (compact) {
    textlist = textlist.filter(@(text) notImportantEventsTexts.indexof(text)==null)
  }
  local elems = textlist.map(function(text){
    if (controlImagesList.indexof(text) != null)
      return makeImg?(text)

    else if (text instanceof ButtonAnd && !eventTypesAsTxt)
      return makeImg(keysImagesMap["__and__"], defHeight/3)

    else if (text in keysImagesMap && eventTypeValues.indexof(text)==null && !(text in eventTypeMap))
      return makeImg(keysImagesMap[text])

    else if (compact && !eventTypesAsTxt && text in keysImagesMap)
      return makeImg?(keysImagesMap?[text], defHeight/2)

    else if (eventTypeValues.indexof(text)!=null)
      return eventTextFunc?(inParents(::loc(text)))

    else if(::type(text)=="string")
      return textFunc?(::loc(text))
    else
      return null
  })
  return elems
}

local function mkHasBinding(actionName){
  return ::Computed(function() {
    local _ = generation // warning disable: -declared-never-used
    return dainput.is_action_binding_set(dainput.get_action_handle(actionName, 0xFFFF), isGamepad.value ? 1 : 0)
  })
}

return {
  isValidDevice = isValidDevice
  buildModifiersList = buildModifiersList
  buildDigitalBindingText = buildDigitalBindingText
  notImportantEventsTexts = notImportantEventsTexts
  textListFromAction = textListFromAction
  makeSvgImgFromText = mkImageComp
  buildElems = buildElems
//  inverseTxt = inverseTxt
  eventTypeLabels = eventTypeLabels
  getSticksText = getSticksText
  mkHasBinding = mkHasBinding
  keysImagesMap = keysImagesMap
}
 