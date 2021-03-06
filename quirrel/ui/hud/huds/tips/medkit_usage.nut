local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local timeStates = require("ui/hud/state/time_state.nut")
local {curTime} = timeStates
local {medkitEndTime, medkitStartTime} = require("ui/hud/state/entity_use_state.nut")
local string = require("string")

local picSz = hdpx(30)
local picProgress = ::Picture("ui/skin#round_border.svg:{0}:{0}:K".subst(picSz.tointeger()))

local bg ={rendObj = ROBJ_VECTOR_CANVAS color = Color(90,90,90,50) fillColor = Color(0,0,0,90) size=[picSz,picSz] commands=[[VECTOR_ELLIPSE, 50, 50, 100, 100]]}

local fgColor = Color(64,255,150)
local bgColor = Color(128,128,128)

local progress = @() {
  pos = [0, ::hdpx(120)]
  size = [picSz,picSz]
  children = [
    bg
    @(){
      rendObj = ROBJ_DTEXT
      watch = [medkitEndTime, curTime]
      text = string.format("%.1f", max(medkitEndTime.value - curTime.value, 0.0))
      hplace=ALIGN_CENTER
      vplace = ALIGN_CENTER
    }
    @(){
      size = [picSz*2,picSz*2]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER
      image = picProgress
      watch = [medkitStartTime, medkitEndTime, curTime]
      fgColor = fgColor
      bgColor = bgColor
      fValue = (curTime.value - medkitStartTime.value) / max(0.1, medkitEndTime.value - medkitStartTime.value)
    }
  ]
}
local showMedkitUsage = ::Computed(@() showPlayerHuds.value && (medkitEndTime.value > timeStates.curTime.value))
return function() {
  return {
    watch = showMedkitUsage
    children = showMedkitUsage.value ? progress : null
  }
}
 