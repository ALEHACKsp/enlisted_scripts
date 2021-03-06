local circleProgressImage = Picture("ui/skin#scanner_range")
local hairColor = Color(160, 160, 160, 120 )
local overheatFg = Color(160, 0, 0, 180)
local overheatBg = Color(0, 0, 0, 0)

local uiCrosshairState = require("ui/hud/huds/crosshair_state_es.nut")
local {overheat, teammateAim, canShoot, isAiming, debugForceCrosshair, crosshairType, crosshairColor} = uiCrosshairState
local xhairEid = uiCrosshairState.eid

local hitHair = require("ui/hud/huds/hit_marks.nut").hitMarks

local crosshairs = {}

local forbid = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [sh(1.5), sh(1.5)]
  commands = [
    [VECTOR_WIDTH, ::hdpx(1.8)],
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0],
  ]
  color = Color(20, 80, 220, 80)

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}

crosshairs.chevron <- @() {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [sh(1.5), sh(1.5)]
  commands = [
    [VECTOR_WIDTH, ::hdpx(1.8)],
    [VECTOR_LINE, 0, 100, 50, 50, 100, 100],
  ]
  color = hairColor

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}

local hair0 = @() {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [pw(25), ::hdpx(5)]
  color = crosshairColor.value.u
  hplace = ALIGN_LEFT
  commands = [
    // set current line width = 4.2
    [VECTOR_WIDTH, ::hdpx(2)],
    [VECTOR_LINE, 0, 50, 100, 50],
  ]
}

local hair1 = @() {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [pw(25), ::hdpx(5)]
  color = crosshairColor.value.u
  hplace = ALIGN_RIGHT
  commands = [
    [VECTOR_WIDTH, ::hdpx(2)],
    [VECTOR_LINE, 0, 50, 100, 50],
  ]
}

local hair2 = @() {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [::hdpx(5), ph(25)]
  color = crosshairColor.value.u
  vplace = ALIGN_BOTTOM
  commands = [
    [VECTOR_WIDTH, ::hdpx(2)],
    [VECTOR_LINE, 50, 0, 50, 100],
  ]
}

crosshairs.t_post <- @() {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    hair0
    hair1
    hair2
  ]
}


local function hitMarkBlock() {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = hitHair
  }
}


local forbidBlock = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = forbid
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


local w = sw(0.2*100)
local h = sh(0.2*100)

local function mkCrosshair(childrenCtor, watch, size=[2*w, 2*h]){
  return @() {
    watch = [xhairEid].extend(watch)
    size = size
    lineWidth = ::hdpx(2)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Crosshair
    transform = {}
    eid = xhairEid.value
    children = childrenCtor()
  }
}
local overlayTransparencyBlock = {
  size =  [sh(3), sh(3)]
  behavior = isAiming.value? Behaviors.OverlayTransparency : null
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}
local mkCrosshairElement = @(children) {size = [sw(100), sh(100)], children = children}

local crosshair = mkCrosshair(@() [
    (teammateAim.value && !isAiming.value) ? forbidBlock : null,
    (debugForceCrosshair.value || (canShoot.value && !isAiming.value && !teammateAim.value)) ? crosshairs?[crosshairType?.value] : null,
    hitMarkBlock,
    overheatBlock,
    overlayTransparencyBlock
  ],
  [canShoot, teammateAim, debugForceCrosshair, isAiming, crosshairType, crosshairColor]
)

local crosshairForbidden = mkCrosshair(@() [(teammateAim.value) ? forbidBlock : null], [teammateAim, isAiming])
local crosshairOverheat = mkCrosshair(@() [overheatBlock], [])
local crosshairHitmarks = mkCrosshair(@() [hitMarkBlock], [])


return {
  crosshair = mkCrosshairElement(crosshair)
  crosshairForbidden = mkCrosshairElement(crosshairForbidden)
  crosshairOverheat = mkCrosshairElement(crosshairOverheat)
  crosshairHitmarks = mkCrosshairElement(crosshairHitmarks)
  crosshairOverlayTransparency = mkCrosshairElement(overlayTransparencyBlock)
}
 