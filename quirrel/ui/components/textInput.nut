local textInputBase = require("daRg/components/textInput.nut")
local colors = require("ui/style/colors.nut")


local function makeFrame(inputObj, group, sf) {
  return {
    rendObj = ROBJ_BOX
    borderWidth = [hdpx(1), hdpx(1), 0, hdpx(1)]
    fillColor = 0
    size = [flex(), SIZE_TO_CONTENT]
    borderColor = (sf.value & S_KB_FOCUS) ? colors.InputFrameLtFocused : colors.InputFrameLt
    group = group
    children = {
      rendObj = ROBJ_BOX
      borderWidth = [0, 0, hdpx(1), 0]
      margin =[0,hdpx(1)]
      fillColor = 0
      size = [flex(), SIZE_TO_CONTENT]
      borderColor = (sf.value & S_KB_FOCUS) ? colors.InputFrameRbFocused : colors.InputFrameRb
      group = group

      children = inputObj
    }
  }
}


local function makeUnderline(inputObj, group, sf) {
  return {
    rendObj = ROBJ_BOX
    borderWidth = [0, 0, hdpx(1), 0]
    fillColor = 0
    size = [flex(), SIZE_TO_CONTENT]
    group = group
    borderColor = (sf.value & S_KB_FOCUS) ? colors.InputFrameRbFocused : colors.InputFrameRb

    children = inputObj
  }
}


local function noFrame(inputObj, group, sf) {
  return inputObj
}


local textInputColors = {
  placeHolderColor = colors.Inactive
  textColor = colors.Active
  backGroundColor = colors.ControlBg
}


local function makeTextInput(text_state, options, handlers, frameCtor) {
  options.colors <- textInputColors
  return textInputBase(text_state, options, handlers, frameCtor)
}


local export = class{
  Framed = @(text_state, options={}, handlers={}) makeTextInput(text_state, options, handlers, makeFrame)
  Underlined = @(text_state, options={}, handlers={}) makeTextInput(text_state, options, handlers, makeUnderline)
  NoFrame = @(text_state, options={}, handlers={}) makeTextInput(text_state, options, handlers, noFrame)
  _call = @(self, text_state, options={}, handlers={}) makeTextInput(text_state, options, handlers, makeFrame)
}()


return export
 