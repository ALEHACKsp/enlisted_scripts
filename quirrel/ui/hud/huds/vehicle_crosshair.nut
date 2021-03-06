local {controlledVehicleEid, vehicleReloadProgress} = require("ui/hud/state/vehicle_state.nut")
local circleProgressImage = Picture("ui/skin#scanner_range")
local aim_color = Color(130, 130, 130, 100)
local aim_bgcolor = Color(0, 0, 0, 25)
local overheatFg = Color(160, 0, 0, 180)
local overheatBg = Color(0, 0, 0, 0)
local overheat = require("ui/hud/state/vehicle_turret_overheat_state.nut")

local function bgAim(){
  return {
    color = aim_bgcolor
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [sh(4.0), sh(4.0)]
    commands = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_ELLIPSE, 50, 50, 50, 50],
    ]
  }
}

local function aim(){
  return {
    color = aim_color
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [sh(4.0), sh(4.0)]
    watch = vehicleReloadProgress
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_SECTOR, 50, 50, 50, 50, -90.0, -90.0 + (vehicleReloadProgress.value ?? 1.0) * 360.0],
    ]
  }
}

local function overheatBlock() {
  return {
    watch = overheat
    opacity = ::min(1.0, overheat.value*2.0)
    fValue = overheat.value
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = circleProgressImage
    size = [sh(4), sh(4)]
    fgColor = overheatFg
    bgColor = overheatBg
  }
}

local crosshair = @() {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  behavior = Behaviors.VehicleCrosshair
  transform = {}

  watch = [controlledVehicleEid]
  eid = controlledVehicleEid.value

  children = [ bgAim aim overheatBlock]
}

local function root() {
  return {
    size = flex()
    children = crosshair
  }
}


return root
 