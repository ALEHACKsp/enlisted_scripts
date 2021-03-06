local colors = require("ui/style/colors.nut")
local {buttonSound} = require("ui/style/sounds.nut")
local math = require("math")
local {sound_play} = require("sound")

local calcFrameColor = @(sf) (sf & S_KB_FOCUS) ? colors.TextActive
                           : (sf & S_HOVER)    ? colors.TextHover
                                               : colors.comboboxBorderColor

local opaque = Color(0,0,0,255)
local calcKnobColor =  @(sf) (sf & S_KB_FOCUS) ? (colors.TextActive | opaque)
                           : (sf & S_HOVER)    ? (colors.TextHover | opaque)
                                               : (colors.TextDefault | opaque)

local scales = {}
scales.linear <- {
  to = @(value, minv, maxv) (value.tofloat() - minv) / (maxv - minv)
  from = @(factor, minv, maxv) factor.tofloat() * (maxv - minv) + minv
}
scales.logarithmic <- {
  to = @(value, minv, maxv) value == 0 ? 0 : math.log(value.tofloat() / minv) / math.log(maxv / minv)
  from = @(factor, minv, maxv) minv * math.pow(maxv / minv, factor)
}
scales.logarithmicWithZero <- {
  to = @(value, minv, maxv) scales.logarithmic.to(value.tofloat(), minv, maxv)
  from = @(factor, minv, maxv) factor == 0 ? 0 : scales.logarithmic.from(factor, minv, maxv)
}
local sliderLeftLoc = ::loc("slider/reduce", "Reduce value")
local sliderRightLoc = ::loc("slider/increase", "Increase value")

local function slider(orient, var, options={}) {
  local minval = options?.min ?? 0
  local maxval = options?.max ?? 1
  local group = options?.group ?? ::ElemGroup()
  local rangeval = maxval-minval
  local scaling = options?.scaling ?? scales.linear
  local step = options?.step
  local unit = options?.unit && options?.scaling!=scales.linear
    ? options?.unit
    : step ? step/rangeval : 0.01
  local pageScroll = options?.pageScroll ?? step ?? 0.05
  local ignoreWheel = options?.ignoreWheel ?? false

  local knobStateFlags = ::Watched(0)
  local sliderStateFlags = ::Watched(0)

  local function knob() {
    return {
      rendObj = ROBJ_SOLID
      size  = [sh(1), sh(2)]
      group = group
      color = calcKnobColor(knobStateFlags.value)
      watch = knobStateFlags
      onElemState = @(sf) knobStateFlags.update(sf)
    }
  }

  local setValue = options?.setValue ?? @(v) var(v)
  local function onChange(factor){
    local value = scaling.from(factor, minval, maxval)
    if (value != var.value)
      sound_play("ui/slider")
    setValue(value)
  }

  local hotkeysElem = {
    key = "hotkeys"
    hotkeys = [
      ["Left | J:D.Left", sliderLeftLoc, function() {
        local delta = maxval > minval ? -pageScroll : pageScroll
        onChange(::clamp(scaling.to(var.value + delta, minval, maxval), 0, 1))
      }],
      ["Right | J:D.Right", sliderRightLoc, function() {
        local delta = maxval > minval ? pageScroll : -pageScroll
        onChange(::clamp(scaling.to(var.value + delta, minval, maxval), 0, 1))
      }],
    ]
  }

  return function() {
    local factor = ::clamp(scaling.to(var.value, minval, maxval), 0, 1)
    return {
      size = flex()
      behavior = Behaviors.Slider
      sound = buttonSound
      watch = [var, sliderStateFlags]
      orientation = orient

      min = 0
      max = 1
      unit = unit
      pageScroll = pageScroll
      ignoreWheel = ignoreWheel

      fValue = factor
      knob = knob

      onChange = onChange
      onElemState = @(sf) sliderStateFlags.update(sf)

      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL

      xmbNode = options?.xmbNode

      children = [
        {
          group = group
          rendObj = ROBJ_SOLID
          color = (sliderStateFlags.value & S_HOVER) ? colors.TextHighlight : colors.TextDefault
          size = [flex(factor), sh(1)]

          children = {
            rendObj = ROBJ_FRAME
            color = calcFrameColor(sliderStateFlags.value)
            borderWidth = [hdpx(1),0,hdpx(1),hdpx(1)]
            size = flex()
          }
        }
        knob
        {
          group = group
          rendObj = ROBJ_SOLID
          color = colors.ControlBgOpaque
          size = [flex(1.0 - factor), sh(1)]

          children = {
            rendObj = ROBJ_FRAME
            color = calcFrameColor(sliderStateFlags.value)
            borderWidth = [1,1,1,0]
            size = flex()
          }
        }
        sliderStateFlags.value & S_HOVER ? hotkeysElem  : null
      ]
    }
  }
}


return {
  Horiz = @(var, options={}) slider(O_HORIZONTAL, var, options)
  scales = scales
}
 