local style = require("ui/hud/style.nut")
local {controlHudHint, mkHasBinding} = require("ui/hud/components/controlHudHint.nut")

local defTextColor = style.HUD_TIPS_FG

local function text_hint(text, params={}){
  return {
    rendObj = ROBJ_DTEXT
    margin = hdpx(2)
    text = text
    color = params?.textColor ?? defTextColor
    font = params?.font ?? Fonts.medium_text
    transform = {pivot=[0.1,0.5]}
    animations = params?.textAnims ?? []
  }
}

local defAnimations = [
  { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[0,1], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

local function mkInputHintBlock(inputId, addChild = null) {
  if (inputId == null)
    return null
  local hasBinding = mkHasBinding(inputId)
  local inputHint = controlHudHint(inputId)
  return @() {
    watch = hasBinding
    flow = FLOW_HORIZONTAL
    children = hasBinding.value ? [inputHint, addChild] : null
  }
}

local padding = {size=[sh(1),0]}
local function tipWidget(params){
  local animations = params?.animations ?? defAnimations
  animations = [].extend(animations).extend(params?.extraAnimations ?? [])
  local textCmp = (params?.text!=null) ? text_hint(params?.text, params) : null
  local extraCmp = params?.extraCmp ?? padding
  local style_override = params?.style ?? {}
  local inputHintBlock = mkInputHintBlock(params?.inputId, padding)
  if (!textCmp && !inputHintBlock)
    return null

  return {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    padding = hdpx(2)
    size = params?.size ?? [SIZE_TO_CONTENT,SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    transform = {
      pivot = [0.5,0.5]
    }
    flow = FLOW_HORIZONTAL
    children = [
      inputHintBlock
      textCmp
      extraCmp
    ]
    animations = animations
  }.__update(style_override)
}

return {
  tipCmp = tipWidget
  mkInputHintBlock = mkInputHintBlock
  defTipAnimations = defAnimations
}
 