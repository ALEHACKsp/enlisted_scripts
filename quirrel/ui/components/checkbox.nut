local colors = require("ui/style/colors.nut")
local {stateChangeSounds} = require("ui/style/sounds.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local {sound_play} = require("sound")
local {isGamepad} = require("ui/control/active_controls.nut")

local calcColor = @(sf)
  (sf & S_ACTIVE) ? colors.CheckBoxContentActive
  : (sf & S_HOVER) ? colors.CheckBoxContentHover
  : colors.CheckBoxContentDefault

local function box(stateFlags, state, group) {
  return @(){
    rendObj = ROBJ_BOX
    fillColor = colors.ControlBg
    borderWidth = hdpx(1)
    borderColor = calcColor(stateFlags.value)
    borderRadius = hdpx(3)
    watch = stateFlags
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      font = Fonts.fontawesome
      size = [fontH(100), fontH(100)]

      children = (state.value!=false)
        ? {
          rendObj = ROBJ_STEXT
          validateStaticText = false
          font = Fonts.fontawesome
          text = fa["check"]
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          color = calcColor(stateFlags.value)
          size = SIZE_TO_CONTENT
          fontSize = state.value==null ? hdpx(8) : hdpx(12)
          opacity = state.value==null ? 0.5 : 1.0
        }
        : null
    }
  }
}

local boxHeight = hdpx(25)//::calc_comp_size({font = Fonts.fontawesome, rendObj = ROBJ_STEXT, fontSize = hdpx(18), text = fa["check"], margin = hdpx(1)})[1]
local mkCheckMark = @(stateFlags, state, group) @(){
  watch = [stateFlags, state]
  validateStaticText = false
  font = Fonts.fontawesome
  text = state.value ? fa["check"] : null
  vplace = ALIGN_CENTER
  color = calcColor(stateFlags.value)
  size = [boxHeight,SIZE_TO_CONTENT]
  fontSize = hdpx(12)
  group = group
  rendObj = ROBJ_STEXT
  halign = ALIGN_CENTER
}

local mkSwitchKnob = @(stateFlags, state, group) @(){
  size = [boxHeight-hdpx(2),boxHeight-hdpx(2)] rendObj = ROBJ_BOX, borderRadius = hdpx(3),
  borderWidth = hdpx(1),
  fillColor = calcColor(stateFlags.value)
  borderColor = Color(0,0,0,30)
  hplace = state.value ? ALIGN_RIGHT : ALIGN_LEFT
  vplace = ALIGN_CENTER
  watch = [stateFlags, state]
  margin = hdpx(1)
  group = group
}

local function switchbox(stateFlags, state, group) {
  local checkMark = mkCheckMark(stateFlags, state, group)
  local switchKnob = mkSwitchKnob(stateFlags, state, group)
  return function(){
    return {
      rendObj = ROBJ_BOX
      fillColor = colors.ControlBg
      borderWidth = hdpx(1)
      borderColor = calcColor(stateFlags.value)
      borderRadius = hdpx(3)
      watch = stateFlags
      size = [boxHeight*2+hdpx(2), boxHeight]
      children = [checkMark, switchKnob]
    }
  }
}

local function label(stateFlags, params, group, onClick) {
  if (::type(params) != ::type({})){
    params = { text = params }
  }
  return @() {
    rendObj = ROBJ_DTEXT
    margin = [sh(1), 0, sh(1), 0]
    color = calcColor(stateFlags.value)
    watch = stateFlags
    grooup = group
    behavior = [Behaviors.Marquee, Behaviors.Button]
    onClick = onClick
    speed = [hdpx(40),hdpx(40)]
    delay =0.3
    scrollOnHover = true
  }.__update(params)
}
local hotkeyLoc = ::loc("controls/check/toggleOrEnable/prefix", "Toggle")
return function (state, label_text_params=null, params = {}) {
  local group = params?.group ?? ::ElemGroup()
  local stateFlags = ::Watched(0)
  local setValue = params?.setValue ?? @(v) state(v)
  local function onClick(){
    setValue(!state.value)
    sound_play(state.value ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
  }
  local hotkeysElem = params?.useHotkeys ? {
    key = "hotkeys"
    hotkeys = [
      ["Left | J:D.Left", hotkeyLoc, onClick],
      ["Right | J:D.Right", hotkeyLoc, onClick],
    ]
  } : null
  return function(){
    local children = [
      isGamepad.value ? switchbox(stateFlags, state, group) : box(stateFlags, state, group),
      label(stateFlags, label_text_params, group, onClick),
      (stateFlags.value & S_HOVER) ? hotkeysElem : null
    ]
    if (params?.textOnTheLeft)
      children.reverse()
    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = sh(1)
      key = state
      group = group
      watch = [state, stateFlags, isGamepad]
      behavior = [Behaviors.Button]
      size = SIZE_TO_CONTENT
      onElemState = @(sf) stateFlags.update(sf)
      onClick = onClick
      sound = stateChangeSounds
      children = children
    }.__update(params?.override ?? {})
  }
}
 