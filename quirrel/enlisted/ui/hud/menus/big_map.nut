local { mmChildrensCtors } = require("ui/hud/huds/minimap/minimap_state.nut")
local { bigmapDefaultVisibleRadius } = require("bigmap_state.nut")
local mmContext = require("ui/hud/huds/minimap/minimap_ctx.nut")
local mouseButtons = require("globals/mouse_buttons.nut")

local { removeInteractiveElement, hudIsInteractive, switchInteractiveElement
} = require("ui/hud/state/interactive_state.nut")
local {isGamepad} = require("ui/control/active_controls.nut")

local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local {DEFAULT_TEXT_COLOR} = require("ui/hud/style.nut")
local JB = require("ui/control/gui_buttons.nut")
local sendMark = require("ui/hud/send_minimap_mark.nut")
local {safeAreaAmount} = require("globals/safeArea.nut")
local {mouseNavTips, placePointsTipGamepad, navGamepadHints, placePointsTipMouse} = require("mapComps.nut")
local {isAlive} = require("ui/hud/state/hero_state_es.nut")
local cursors = require("ui/style/cursors.nut")

local showBigMap = persist("showBigMap", @() Watched(false))

local mapSize = Computed(@() [safeAreaAmount.value*sh(76), safeAreaAmount.value*sh(76)])

isAlive.subscribe(function(live) {
  if (!live)
    showBigMap(false)
})

showBigMap.subscribe(@(val) removeInteractiveElement("bigMap"))

local mapRootAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]


local minimapState = ::MinimapState({
  ctx = mmContext
  visibleRadius = bigmapDefaultVisibleRadius.value
  shape = "square"
})
local mapTransform = { rotate = 90 }
local markersTransform = {rotate = -90}

bigmapDefaultVisibleRadius.subscribe(@(r) minimapState.setVisibleRadius(r))

local visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
}

local modeHotkeyTip = tipCmp({
  text = ::loc("controls/HUD.Interactive")
  inputId = "HUD.Interactive"
  textColor = DEFAULT_TEXT_COLOR
  main_params= {
    size = [SIZE_TO_CONTENT, ph(100)]
  }
  animations = []
  style = {rendObj=null}
})

local mkPlacePointsTip = @(mapSize, addChild) @() {
  watch = [mapSize, isGamepad]
  size = [mapSize.value[0], SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = sh(0.5)
  children = [
    //modeHotkeyTip
    isGamepad.value ? navGamepadHints : mouseNavTips
    isGamepad.value ? placePointsTipGamepad : placePointsTipMouse
    addChild
  ]
}
local mkInteractiveTips = @(internactiveTips, notInteractiveTips) @() {
  watch = hudIsInteractive
  size = [flex(), fontH(430)]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  flow = FLOW_VERTICAL
  gap = sh(0.5)
  padding = [sh(1), 0]
  halign = ALIGN_CENTER
  children = hudIsInteractive.value ? internactiveTips : notInteractiveTips
}

local function interactiveFrame() {
  local res = { watch = hudIsInteractive }
  if (!hudIsInteractive.value)
    return res
  return res.__update({
    rendObj = ROBJ_FRAME
    size = flex()
    borderWidth = ::hdpx(2)
    color = Color(180,160,10,130)

    childen = {
      // use frame since parent already has another hook
      hooks = HOOK_ATTACH
      actionSet = "StopInput"
    }
  })
}

local bigMapEventHandlers = {
  ["HUD.Interactive"] = @(event) switchInteractiveElement("bigMap"),
  ["HUD.Interactive:end"] = function onHudInteractiveEnd(event) {
    if (showBigMap.value && ((event?.dur ?? 0) > 500 || event?.appActive == false))
      removeInteractiveElement("bigMap")
  }
}

local closeMapDesc = {
  action = @() showBigMap(false),
  description = ::loc("Close"),
  inputPassive = true
}

local mkMapLayer = @(ctorWatch, paramsWatch, map_size) @() {
  watch = [ctorWatch, paramsWatch]
  size = map_size
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  clipChildren = true
  eventPassThrough = true
  minimapState = minimapState
  transform = mapTransform
  behavior = Behaviors.Minimap
  children = ctorWatch.value.ctor(paramsWatch.value)
}

local interactiveTips = mkInteractiveTips(
  mkPlacePointsTip(mapSize, null),
  modeHotkeyTip)

local function onClickMap(e){
  if (e.button==1 || (isGamepad.value && e.button==0))
    sendMark(e, minimapState)
}
local function onDoubleClickMap(e) {
  sendMark(e, minimapState)
}

local markersParams = ::Computed(@() {
  state = minimapState
  size = mapSize.value
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = hudIsInteractive.value
  showHero = true
})

local baseMap = @() {
  size = mapSize.value
  watch = mapSize
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  transform = mapTransform
  panMouseButton = mouseButtons.MMB
  behavior = hudIsInteractive.value
    ? [Behaviors.Minimap, Behaviors.Button, Behaviors.MinimapInput]
    : [Behaviors.Minimap]
  color = Color(255, 255, 255, 200)

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  clipChildren = true
  eventPassThrough = true
  stickCursor = false
  children = [visCone]

  onClick = onClickMap
  onDoubleClick = onDoubleClickMap
}

local mapLayers = @() {
  hooks = HOOK_ATTACH
  actionSet = "BigMap"
  watch = [mmChildrensCtors, mapSize]
  size = mapSize.value
  children = [
    baseMap
  ]
    .extend(mmChildrensCtors.value.map(@(c) mkMapLayer(c, markersParams, mapSize.value)))
    .append(interactiveFrame)
}

local framedMap = @() {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = Color(140,140,140,255)
  padding = sh(1)
  watch = mapSize
  children = mapLayers
}

local mapBlock = @(){
  watch = hudIsInteractive
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    framedMap
    interactiveTips
  ]
}

local function bigMap() {
  local needCursor = hudIsInteractive.value
  return {
    watch = hudIsInteractive
    key = "big_map"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    cursor = needCursor ? cursors.normal : null
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }

    children = mapBlock

    animations = mapRootAnims
    hotkeys = [
      [ "Esc", closeMapDesc],
      [ $"^{JB.B}", closeMapDesc],
      [ "@HUD.BigMap", closeMapDesc ],
      [$"J:RB | J:LB"] //just mask them out
    ]
    eventHandlers = bigMapEventHandlers
  }
}

return {
  bigMap
  showBigMap
}
 