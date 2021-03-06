local {HUD_TIPS_HOTKEY_FG} = require("ui/hud/style.nut")
local {textListFromAction, buildElems, mkHasBinding, keysImagesMap} = require("ui/control/formatInputBinding.nut")
local {isGamepad} = require("ui/control/active_controls.nut")

local function container(children, params={}){
  return {
    children = {
      speed = [60,800]
      delay = 0.3
      children = children
      flow = FLOW_HORIZONTAL
      gap = hdpx(3)
      behavior = [Behaviors.Marquee]
      scrollOnHover = true
      maxWidth = pw(100)
      size = SIZE_TO_CONTENT
      halign = ALIGN_LEFT valign = ALIGN_CENTER
    }
    clipChildren = true
    size = SIZE_TO_CONTENT
  }.__update(params)
}

local function controlHudHint(params, group = null) {
  if (typeof params == "string")
    params = {id = params}
  local frame = params?.frame ?? true
  local font = params?.text_params?.font ?? Fonts.small_text
  local color = params?.color ?? HUD_TIPS_HOTKEY_FG
  local width = params?.width ?? SIZE_TO_CONTENT
  local height = params?.height ?? fontH(100)
  local function makeControlText(text) {
    return {
      text=text font=font, color = color, rendObj = ROBJ_DTEXT padding = hdpx(4)
    }
  }
  local hasBinding = mkHasBinding(params.id)
  return function(){
    local disableFrame = params?.disableFrame ?? isGamepad.value
    local column = isGamepad.value ? 1 : 0
    local textList = textListFromAction(params.id, column)
    local hasTexts = false
    foreach (e in textList) {
      if (keysImagesMap?[e] == null){
        hasTexts=true
        break
      }
    }
    disableFrame = disableFrame || !hasTexts
    local controlElems = buildElems(textList, {textFunc = makeControlText, compact = true})
    local elems = container(controlElems, params?.text_params ?? {})
    return {
      size = [width, height]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      minWidth = height
      font = font
      clipChildren = width != SIZE_TO_CONTENT
      children = [
        elems
        frame && !disableFrame ? { rendObj = ROBJ_FRAME, color = color, size = flex(), opacity = 0.3} : null
      ]
      watch = [isGamepad, hasBinding]
    }
  }
}

local defTextFunc = @(text){
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_FRAME
  color = ::mul_color(HUD_TIPS_HOTKEY_FG,0.3)
  padding = hdpx(1)
  children = [
    {rendObj=ROBJ_WORLD_BLUR_PANEL size = flex() fillColor = Color(0,0,0,30)}
    {
      text=text font=Fonts.small_text, color = HUD_TIPS_HOTKEY_FG, rendObj = ROBJ_DTEXT
      margin = [hdpx(1),hdpx(2)]
      size = SIZE_TO_CONTENT
    }
  ]
}
local function mkShortHudHintFromList(controlElems, watch = null){
  local modifier = null
  local hasModifier = controlElems.len()==2
  if (hasModifier) {
    modifier = controlElems[1]
    controlElems = [controlElems[0]]
  }
  modifier = {hplace = ALIGN_RIGHT, size = SIZE_TO_CONTENT, children = modifier, padding = [0,0,0,hdpx(15)], pos=[0,-hdpx(2)]}
  controlElems.append(modifier)
  return {
    watch = [isGamepad].extend(watch ?? [])
    size = SIZE_TO_CONTENT
    flow = hasModifier ? null : FLOW_HORIZONTAL
    valign = hasModifier ? null : ALIGN_CENTER
    children = controlElems
    vplace = ALIGN_CENTER
  }
}

local function shortHudHint(params = {textFunc=defTextFunc, alternateId=null}){
  const eventTypeToText = false
  if (::type(params)=="string")
    params = { id = params}
  local textFunc = params?.textFunc ?? defTextFunc
  local hasBinding = mkHasBinding(params.id)
  local hasAltBinding = params?.alternateId != null ? mkHasBinding(params.alternateId) : null
  return function(){
    local column = isGamepad.value ? 1 : 0
    local textList = textListFromAction(params.id, column, eventTypeToText)
    if (textList.len()==0 && params?.alternateId != null) {
      textList = textListFromAction(params.alternateId, column, eventTypeToText)
    }
    local controlElems = buildElems(textList, {textFunc = textFunc, compact = true})
    return mkShortHudHintFromList(controlElems, [hasBinding, hasAltBinding])
  }
}

return {
  controlHudHint = controlHudHint
  shortHudHint = shortHudHint
  mkShortHudHintFromList = mkShortHudHintFromList
  mkHasBinding = mkHasBinding
}
 