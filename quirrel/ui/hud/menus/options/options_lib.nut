local math = require("math")
local { DEFAULT_TEXT_COLOR } = require("ui/hud/style.nut")
local mkOnlineSaveData = require("enlist/options/mkOnlineSaveData.nut")
local slider = require("ui/components/slider.nut")
local mkSliderWithText = require("ui/components/optionTextSlider.nut")
local optionCheckBox = require("ui/components/optionCheckBox.nut")
local optionCombo = require("ui/components/optionCombo.nut")
local optionSlider = require("ui/components/optionSlider.nut")
local optionButton = require("ui/components/optionButton.nut")
local optionHSelect = require("ui/components/optionHSelect.nut")
local optionTextArea = require("ui/components/optionTextArea.nut")

local getOnlineSaveData = ::memoize(@(saveId, defValueFunc, validateFunc = @(v) v) mkOnlineSaveData(saveId, defValueFunc, validateFunc))

local function defCmp(a, b) {
  if (typeof a != "float")
    return a == b
  local absSum = math.fabs(a) + math.fabs(b)
  return absSum < 0.00001 ? true : math.fabs(a - b) < 0.0001 * absSum
}

local loc_opt = @(s) ::loc($"option/{s}")

local function optionPercentTextSliderCtor(opt, group, xmbNode) {
  return mkSliderWithText(opt.var, slider.Horiz(opt.var, opt), @(v) "{0}%".subst(v))
}

local optionDisabledText = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  clipChildren = true
  rendObj = ROBJ_DTEXT //do not made this stext as it can eat all atlas
  font = Fonts.medium_text
  text = text
  color = DEFAULT_TEXT_COLOR
}

local mkDisableableCtor = @(disableWatch, enabledCtor, disabledCtor = optionDisabledText)
  function(opt, group, xmbNode) {
    local enabledWidget = enabledCtor(opt, group, xmbNode)
    return @() {
      watch = disableWatch
      size = flex()
      valign = ALIGN_CENTER
      children = disableWatch.value == null ? enabledWidget
        : disabledCtor(disableWatch.value)
    }
  }

return {
  defCmp
  loc_opt
  getOnlineSaveData
  slider
  mkSliderWithText
  optionPercentTextSliderCtor
  optionSlider
  optionCombo
  optionHSelect
  optionCheckBox
  optionButton
  optionTextArea
  optionDisabledText
  mkDisableableCtor
}
 