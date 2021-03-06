local {hudIsInteractive} = require("ui/hud/state/interactive_state.nut")

local mmContext = require("minimap_ctx.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local command = require("ui/hud/send_minimap_mark.nut")
local {controlHudHint} = require("ui/hud/components/controlHudHint.nut")
local { mmChildrensCtors, minimapDefaultVisibleRadius } = require("minimap_state.nut")
local mouseButtons = require("globals/mouse_buttons.nut")

local mapSize = [sh(20), sh(20)]
local mapContentMargin = sh(0.5)//needed because of compass arrows that are out of size

local MMSHAPES = {
  SQUARE = {
    rendType = "square"
    rotate = 90
    minimapObjsTransform = {rotate=-90}
    blurBackMask = null
    clipChildren = true
    viewDependentRotation = false
    canvasInteractive = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_RECTANGLE, 0.5, 0.5, 99.5, 99.5],
    ]
  },
  CIRCLE = {
    blurBackMask = ::Picture("ui/uiskin/white_circle.png?Ac")
    rendType = "circle"
    rotate = 0
    minimapObjsTransform = {rotate=0}
    viewDependentRotation=true
    clipChildren = false
    canvasInteractive = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_ELLIPSE, 50, 50, 49.5, 49.5]
    ]
  }
}

local curMinimapShape = MMSHAPES.SQUARE
local minimapState = ::MinimapState({
  ctx = mmContext
  visibleRadius = minimapDefaultVisibleRadius.value
  shape = curMinimapShape.rendType
})
minimapDefaultVisibleRadius.subscribe(@(r) minimapState.setVisibleRadius(r))
local mapTransform = { rotate = curMinimapShape.rotate }


local blurredWorld = {
  rendObj = ROBJ_MASK
  image = curMinimapShape.blurBackMask
  size = mapSize
  children = {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = flex()
  }
}


local regionsGeometry = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_REGIONS_GEOMETRY
  behavior = Behaviors.Minimap
}

local visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
}

local function onClick(e){
  if (e.button == 1 || isGamepad.value)
    command(e, minimapState)
}
local function onDoubleClick(e) {
  command(e, minimapState)
}


local mapHotKey = {
  children = controlHudHint("HUD.BigMap")
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  margin = [hdpx(3),hdpx(3)]
  opacity = 0.7
}

local baseMap = {
  size = mapSize
  transform = mapTransform
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  behavior = Behaviors.Minimap
  margin = mapContentMargin

  children = [regionsGeometry, visCone]
}

local commonLayerParams = {
  state = minimapState
  size = mapSize
  isCompassMinimap = curMinimapShape.viewDependentRotation
  transform = curMinimapShape.minimapObjsTransform
  showHero = false
}

local mkMinimapLayer = @(ctorWatch, params) @() {
  watch = ctorWatch
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  clipChildren = params?.clipChildren ?? curMinimapShape.clipChildren
  minimapState = minimapState
  transform = mapTransform
  behavior = Behaviors.Minimap
  children = ctorWatch.value.ctor(params)
}

local noClipMap = @(panButton) @() {
  watch = hudIsInteractive
  size = mapSize
  transform = mapTransform
  minimapState = minimapState
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = mapContentMargin
  stickCursor = false
  eventPassThrough = true
  panMouseButton = panButton
  behavior = hudIsInteractive.value
    ? [Behaviors.Button, Behaviors.MinimapInput]
    : null
  onClick = onClick
  skipDirPadNav = true
  onDoubleClick = onDoubleClick
}

local interactiveCanvas = @() {
  watch = hudIsInteractive
  size = flex()
  children = hudIsInteractive.value
    ? {
        rendObj = ROBJ_VECTOR_CANVAS
        color = Color(180,160,10,130)
        fillColor = Color(0,0,0,0)
        size = flex()
        commands = curMinimapShape.canvasInteractive
      }
    : null
}

local function makeMinimap(panButton = mouseButtons.LMB) {
  return @() {
    watch = mmChildrensCtors
    size = mapSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = curMinimapShape.clipChildren

    children = [
      blurredWorld,
      baseMap,
    ]
      .extend(mmChildrensCtors.value.map(@(c) mkMinimapLayer(c, commonLayerParams)))
      .append(
        interactiveCanvas,
        noClipMap(panButton),
        mapHotKey
      )
  }
}

return ::kwarg(makeMinimap)
 