local {awards} = require("ui/hud/state/eventlog.nut")
local {lerp} = require("std/math.nut")
require("ui/hud/state/awards.nut")

local numAnimations = [
  { prop=AnimProp.opacity, from=0.0, to=0.0, delay=0.0, duration=0.1, play=true easing=OutCubic }
  { prop=AnimProp.scale, from=[2,2], to=[1,1], delay=0.1, duration=0.5, play=true easing=OutCubic }
  { prop=AnimProp.opacity, from=0.0, to=1.0, delay=0.1, duration=0.5, play=true easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[2,2], delay=0.0, duration=0.1, playFadeOut=true easing=OutCubic }
  { prop=AnimProp.opacity, from=1.0, to=0.0, delay=0.1, duration=0.1, playFadeOut=true easing=OutCubic }
]

local font = Fonts.medium_text
local color = Color(130,130,130,80)

local xtext= {
  rendObj = ROBJ_STEXT text = "x" color = color font = font fontSize=sh(1)
  transform={pivot = [0.5, 0]}
  hplace = ALIGN_CENTER halign = ALIGN_CENTER vplace = ALIGN_CENTER valign = ALIGN_CENTER
  pos = [0, sh(0.5)]
}

local function mkAwardText(text, params = {}){
  return {
    rendObj = ROBJ_DTEXT
    font = font
    text = text
    color = color
    hplace = ALIGN_CENTER
    fontFxColor = Color(0, 0, 0, 60)
    fontFxFactor = min(::hdpx(32).tointeger(), 64)
    fontFx = FFT_GLOW
  }.__merge(params)
}

local awardHgt = ::calc_comp_size(mkAwardText("H"))[1].tointeger()
const maxAwardsToShow = 5
local transitions = [
  { prop = AnimProp.translate, duration = 0.3, easing = OutQuad }
  { prop = AnimProp.opacity, duration = 0.1, easing = OutQuad }
]
local pivot = [0.5, 0.5]
local gap = awardHgt/3

local mkMainAwardAnimations = @(normidx, opacity) [
  { prop=AnimProp.scale, from=[1,1], to=[1,0.2], delay=0.0, duration=0.2, playFadeOut=true, easing=OutCubic}
  { prop=AnimProp.translate, from=[0, awardHgt*3], to=[0, awardHgt*3 + sh(8)], delay=0.0, duration=0.6, playFadeOut=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=min(opacity, 0.6), to=0, duration=0.4, playFadeOut=true easing=OutCubic}
  { prop=AnimProp.scale, from=[1,0], to=[1,1], delay=0.0, duration=0.2, play=true, easing=OutCubic}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true }
]


local awardIconsByType = {
  kill = @(key){
    rendObj = ROBJ_IMAGE
    image = ::Picture($"ui/skin#skull.svg:{awardHgt}:{awardHgt}:K")
    size = [awardHgt, awardHgt]
    transform = {}
    key = key
    opacity = 1
    color = color
    animations = [
      { prop=AnimProp.scale, from=[2,2], to=[1,1], duration=0.5, play=true, easing=InOutQuintic}
      { prop=AnimProp.opacity, from=0, to=1, duration=0.4, play=true, easing=InOutQuintic }
    ]
  }
}
local function makeAward(item, idx, col) {
  local len = col.len()
  local normidx = len - 1 - idx
  local awardType = item.awardData.type
  local text = item.awardData?.text ?? loc($"hud/awards/{awardType}", awardType)
  local key = item?.key
  local num = item?.num
  local awardIcon = awardIconsByType?[awardType]($"{key}_{num}")
  local awardText = mkAwardText(text ?? "")
  local numText = num!=null
    ? {
      flow = FLOW_HORIZONTAL
      children = [xtext, mkAwardText(num, {animations = numAnimations, transform = {pivot=pivot}})]
    }
    : null
  local opacity = clamp(lerp(maxAwardsToShow-3, maxAwardsToShow-1, 1.0, 0.4, normidx), 0, 1)
  return {
    key = key
    gap = gap
    flow = FLOW_HORIZONTAL
    size = SIZE_TO_CONTENT
    children = [
      awardIcon
      awardText
      numText
    ]
    opacity = opacity
    animations = mkMainAwardAnimations(normidx, opacity)
    transform = {
      translate = [0, awardHgt * normidx]
      pivot = pivot
    }
    transitions = transitions
  }
}

local function awardsRoot() {
  local children = awards.events.value.map(makeAward)
  local len = awards.events.value.len()
  if (len > maxAwardsToShow)
    children = children.slice(len-maxAwardsToShow)
  children.reverse()
  return {
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    gap = hdpx(2)
    size = [pw(30), maxAwardsToShow*awardHgt + gap*(maxAwardsToShow-1)]

    watch = awards.events
    children = children
  }
}


return awardsRoot
 