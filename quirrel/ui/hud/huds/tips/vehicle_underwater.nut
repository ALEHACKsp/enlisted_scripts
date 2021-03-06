local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local timeState = require("ui/hud/state/time_state.nut")
local {curTime} = timeState
local {vehicleUnderWaterEndTime, vehicleUnderWaterMaxTime} = require("ui/hud/state/vehicle_underwater_state.nut")
local string = require("string")
local picSz = hdpx(30)
local picProgress = ::Picture("ui/skin#round_border.svg:{0}:{0}:K".subst(picSz.tointeger()))

local bg ={rendObj = ROBJ_VECTOR_CANVAS color = Color(90,90,90,50) fillColor = Color(0,0,0,90) size=[picSz,picSz] commands=[[VECTOR_ELLIPSE, 50, 50, 100, 100]]}

local fgColor = Color(230,30,150)
local bgColor = Color(128,128,128)

local progress = {
  pos = [0, ::hdpx(120)]
  size = [picSz,picSz]
  children = [
    bg
    @(){
      rendObj = ROBJ_DTEXT
      watch = [vehicleUnderWaterEndTime, curTime]
      text = string.format("%.1f", max(vehicleUnderWaterEndTime.value - curTime.value, 0.0))
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER}
    @(){
      size = [picSz*2,picSz*2]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER
      image = picProgress
      watch = [vehicleUnderWaterEndTime, vehicleUnderWaterMaxTime, curTime]
      fgColor = fgColor
      bgColor = bgColor
      fValue = (vehicleUnderWaterEndTime.value - curTime.value) / vehicleUnderWaterMaxTime.value
    }
  ]
}

local vehicleUnderWater = ::Computed(@() showPlayerHuds.value && vehicleUnderWaterEndTime.value > timeState.curTime.value)
return function() {
  return {
    watch = [vehicleUnderWater]
    children = vehicleUnderWater.value ? progress : null
  }
}
 