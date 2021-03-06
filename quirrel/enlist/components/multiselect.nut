local fa = require("daRg/components/fontawesome.map.nut")
local {CheckBoxContentActive, CheckBoxContentHover, CheckBoxContentDefault, ControlBg} = require("ui/style/colors.nut")
local {gap, bigGap} = require("enlist/viewConst.nut")
local {sound_play} = require("sound")
local multiselect = require("daRg/components/multiselect.nut")
local {stateChangeSounds} = require("ui/style/sounds.nut")

local font = Fonts.medium_text
local checkFontSize = hdpx(12)
local boxSize = hdpx(20)
local calcColor = @(sf)
  (sf & S_ACTIVE) ? CheckBoxContentActive
  : (sf & S_HOVER) ? CheckBoxContentHover
  : CheckBoxContentDefault

local function box(isSelected, sf) {
  local color = calcColor(sf)
  return {
    size = [boxSize, boxSize]
    rendObj = ROBJ_BOX
    fillColor = ControlBg
    borderWidth = hdpx(1)
    borderColor = color
    borderRadius = hdpx(3)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = isSelected
      ? {
        rendObj = ROBJ_STEXT
        font = Fonts.fontawesome
        text = fa["check"]
        color = color
        fontSize = checkFontSize
        validateStaticText = false
      }
      : null
  }
}

local label = @(text, sf) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_DTEXT
  color = calcColor(sf)
  text = text
  font = font
  behavior = [Behaviors.Marquee]
  scrollOnHover = true
}

local function optionCtor(option, isSelected, onClick) {
  local stateFlags = ::Watched(0)
  return function() {
    local sf = stateFlags.value

    return {
      size = [flex(), SIZE_TO_CONTENT]
      padding = [sh(0.5),sh(1.0),sh(0.5),sh(1.0)]
      watch = stateFlags
      behavior = Behaviors.Button
      onElemState = @(s) stateFlags(s)
      onClick = function() {
        sound_play(isSelected ? "ui/enlist/flag_unset" : "ui/enlist/flag_set")
        onClick()
      }
      sound = stateChangeSounds
      stopHover = true

      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = bigGap
      children = [
        box(isSelected, sf)
        label(option.text, sf)
      ]
    }
  }
}

local style = {
  root = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = gap
  }
  optionCtor = optionCtor
}

return @(params) multiselect({ style = style }.__update(params)) 