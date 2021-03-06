local { missionName } = require("enlisted/ui/hud/state/mission_params.nut")
local {set_fully_covering} = require("loading")
local {levelIsLoading} = require("ui/hud/state/appState.nut")
local {format} = require("string")
local {appBgImages} = require("ui/appBgImages.nut")
local {mkParallaxBkg, mkAnimatedEllipsis} = require("ui/loading/loadingComponents.nut")
local {shuffle} = require("std/rand.nut")
local {verPadding, horPadding} = require("globals/safeArea.nut")

local {loadingImages} = require("enlisted/ui/hud/state/loading.nut")

//local berlin_loading_images = array(29).map(@(v,idx) format("ui/loading_berlin_%02d", idx))
local campaignLoadingImages = Watched(shuffle(::array(19).map(@(v,idx) format("ui/loading_volokolamsk_%02d", idx))))

local imagesToChange = Computed(function(){
  return []
    .extend(shuffle(loadingImages.value ?? []))
    .extend(shuffle(campaignLoadingImages.value ?? appBgImages.value))
})

local curTipIdx = Watched(0)
local function changeTip(delta){
  local total = imagesToChange.value?.len() ?? 0
  if (total==0)
    return
  local cur = curTipIdx.value
  local nextIdx = (cur+delta+total)%total
  curTipIdx(nextIdx)
}
const defaultTimeToSwitch = 20
const defaultAutoTimeToSwitch = 15
local function nextTipAuto(){
  changeTip(1)
}
local function nextTip() {
  ::gui_scene.clearTimer(nextTipAuto)
  ::gui_scene.clearTimer(::callee())
  ::gui_scene.setTimeout(defaultTimeToSwitch, ::callee())
  changeTip(1)
}
local function prevTip(){
  ::gui_scene.clearTimer(nextTipAuto)
  ::gui_scene.clearTimer(nextTip)
  ::gui_scene.setTimeout(defaultTimeToSwitch, nextTip)
  changeTip(-1)
}
::gui_scene.setInterval(defaultAutoTimeToSwitch, nextTipAuto)

local imageToShow = ::Computed(@() imagesToChange.value?[curTipIdx.value])

local showImage = keepref(::Computed(@() imageToShow.value!=null && !levelIsLoading.value))
showImage.subscribe(set_fully_covering)

local color = Color(160,160,160,160)

local fontSize = hdpx(25)
local animatedEllipsis = mkAnimatedEllipsis(fontSize, color)

local animatedLoading = @(){
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  watch = verPadding
  valign = ALIGN_CENTER
  pos = [-sh(7),-verPadding.value-sh(3)]
  children = [
    {
      rendObj = ROBJ_DTEXT
      text = ::loc("Loading")
      font = Fonts.huge_text
      color = color
    }
    {size=[hdpx(4),0]}
    animatedEllipsis
  ]
}

const parallaxK = -0.025
local letterBoxHeight=(sh(100) - sw(100)/16*9)/2
if (letterBoxHeight < 0)
  letterBoxHeight = 0

local letterboxUp = {rendObj = ROBJ_SOLID size=[flex(), letterBoxHeight], color = Color(0,0,0)}
local letterboxDown = letterboxUp.__merge({vplace=ALIGN_BOTTOM})


local loadingBkg = mkParallaxBkg(imageToShow, parallaxK, (sh(100)-letterBoxHeight*2), sw(100))

local blackScreen = {
  rendObj = ROBJ_SOLID
  color = Color(0,0,0)
  size = flex()
}

local tipsHotkeys = @() {
  size = flex()
  children = {
    behavior = Behaviors.Button
    size = flex()
    hotkeys = [
      ["^A | Down | S | M:0", prevTip],
      ["^W | Up | D | | M:1", nextTip],
      ["^J:D.Left | Left", prevTip],
      ["^J:D.Right | Right", nextTip]
    ]
  }
}

local decoratedImage = @(){
  size = flex()
  watch = imageToShow
  children = imageToShow.value !=null ? [
    blackScreen
    loadingBkg
    letterboxUp
    letterboxDown
  ] : null
}

local missionTitle = @(){
  watch = missionName
  rendObj = ROBJ_DTEXT
  text = ::loc(missionName.value)
  font = Fonts.huge_text
  margin = [verPadding.value + sh(5), horPadding.value + sw(7)]
  color = color
  fontFxColor = Color(0,0,0,190)
  fontFxFactor = min(64, hdpx(64))
  fontFx = FFT_SHADOW
  fontFxOffsX = min(2,hdpx(2))
  fontFxOffsY = min(2, hdpx(2))
}
local screen = {
  size = flex()
  children = [
    decoratedImage
    tipsHotkeys
    missionTitle
    animatedLoading
  ]
}

return screen
 