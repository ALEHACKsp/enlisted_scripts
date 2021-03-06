local {controlledVehicleEid} = require("ui/hud/state/vehicle_state.nut")
local {mainTurretEid} = require("ui/hud/huds/player_info/vehicle_turret_state.nut")

local lineWidth = max(1.1, hdpx(1.2))
local forbid = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [sh(1.5), sh(1.5)]
  commands = [
    [VECTOR_WIDTH, lineWidth],
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0],
  ]
  color = Color(20, 80, 220, 80)

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}


local function hair(color, line, width=null) {
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    size = flex()
    color = color
    commands = [
      [VECTOR_WIDTH, width ?? lineWidth],
      line
    ]
  }
}

local w = sh(2)
local h = sh(2)
local crossHairSize = [2*w, 2*h]
const chPart = 35
local hair0 = @(color, width=null) hair(color, [VECTOR_LINE, 0, 50, chPart, 50], width)
local hair1 = @(color, width=null) hair(color, [VECTOR_LINE, 100-chPart, 50, 100, 50], width)
local hair2 = @(color, width=null) hair(color, [VECTOR_LINE, 50, 100-chPart, 50, 100], width)

local colorNotPenetrated = Color(245, 30, 30)
local colorInEffective = Color(150, 150, 140)
local colorEffective = Color(30, 255, 30)
local colorPossibleEffective = Color(230, 230, 20)
local colorShadow = Color(0,0,0,100)
local mkBlockImpl = @(color, pos = null, width=null) {size = crossHairSize, children = [hair0(color, width), hair1(color, width), hair2(color, width)], pos=pos}
local mkBlock = @(xhairMode, color) {size = crossHairSize, xhairMode = xhairMode, children = [mkBlockImpl(color), mkBlockImpl(colorShadow, [0, hdpx(1)], lineWidth*2)]}

local aimNotPenetratedBlock = mkBlock("aimNotPenetrated", colorNotPenetrated)
local aimIneffectiveBlock = mkBlock("aimIneffective", colorInEffective)
local aimEffectiveBlock = mkBlock("aimEffective", colorEffective)
local aimPossibleEffectiveBlock = mkBlock("aimPossibleEffective", colorPossibleEffective)


local forbidBlock = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  xhairMode = "teammate"
  children = [
    forbid
  ]
}

local function crosshair() {
  return {
    size = crossHairSize
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.TurretCrosshair
    transform = {}

    watch = [controlledVehicleEid, mainTurretEid]
    eid = controlledVehicleEid.value
    turretEid = mainTurretEid.value

    children = [
      forbidBlock
      aimNotPenetratedBlock
      aimIneffectiveBlock
      aimEffectiveBlock
      aimPossibleEffectiveBlock
    ]
  }
}


local function root() {
  return {
    size = [sw(100), sh(100)]
    children = crosshair
  }
}


return root
 