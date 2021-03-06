local {isDowned, isAlive} = require("ui/hud/state/hero_state_es.nut")
local {isSpectator} = require("ui/hud/state/spectator_state.nut")
local {downedEndTime} = require("ui/hud/state/downed_state.nut")
local {medkitEndTime, medkitStartTime} = require("ui/hud/state/entity_use_state.nut")
local {curTime} = require("ui/hud/state/time_state.nut")
local string = require("string")

local color0 = Color(200,40,40,110)
local color1 = Color(200,200,40,180)
local overlapTipWithHeal = 1.0
local isInDowned = ::Computed(@() isDowned.value && isAlive.value)

local animColor = [
  { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull }
]
local animAppear = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack }]

local pivot = {pivot=[0,0.5]}
local tip = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  padding = hdpx(2)
  size = [SIZE_TO_CONTENT,SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  transform = pivot
  animations = animAppear
  flow = FLOW_HORIZONTAL
  children = [
    @(){
      font = Fonts.medium_text
      rendObj = ROBJ_DTEXT
      text = ::loc(isSpectator.value ? "tips/spectator_downed_tip" : "tips/downed_tip", {
        timeLeft = string.format("%d", max(downedEndTime.value - curTime.value, 0.0))
      })
      color = color0
      transform = pivot
      watch = [downedEndTime, curTime, isSpectator]
      animations = animColor
    }
  ]
}
local function mkTip(){//try to avoid subscribe on timechange - to safe performance and clear profiler
  local needTip = ::Computed(@()
      (downedEndTime.value > curTime.value) && ((medkitEndTime.value < curTime.value) || (medkitStartTime.value + overlapTipWithHeal > curTime.value)))
  return @(){
    watch = needTip
    size = SIZE_TO_CONTENT
    children = needTip.value ? tip : null
  }
}
return function() {
  return {
    watch = isInDowned
    size = SIZE_TO_CONTENT
    children = !isInDowned.value ? null : mkTip()
  }
}

 