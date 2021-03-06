local mmContext = require("ui/hud/huds/minimap/minimap_ctx.nut")
local {mmChildrensCtors} = require("ui/hud/huds/minimap/minimap_state.nut")
local {removeInteractiveElement, addInteractiveElement, hudIsInteractive} = require("ui/hud/state/interactive_state.nut")
local {closeMenu} = require("ui/hud/hud_menus.nut")
local mouseButtons = require("globals/mouse_buttons.nut")
local JB = require("ui/control/gui_buttons.nut")
local {isGamepad} = require("ui/control/active_controls.nut")
local {DEFAULT_TEXT_COLOR} = require("ui/hud/style.nut")
local cursors = require("ui/style/cursors.nut")
local {isAlive, isDowned} = require("ui/hud/state/hero_state_es.nut")
local {isRadioMode} = require("enlisted/ui/hud/state/enlisted_hero_state.nut")
local { CmdHeroSpeech } = require("speechevents")
local { sound_play } = require("sound")
local {get_controlled_hero} = require("globals/common_queries.nut")
local {safeAreaAmount} = require("globals/safeArea.nut")
local {hintTextFunc, mouseNavTips, mkTips, navGamepadHints} = require("mapComps.nut")

local showArtilleryMap = persist("showArtilleryMap", @() Watched(false))

local mapSize = Computed(@() [safeAreaAmount.value*sh(76), safeAreaAmount.value*sh(76)])
local title = "map/artillery"
local tipLmb = "map/artilleryStrike"


isAlive.subscribe(function(live) {
  if (!live)
    showArtilleryMap(false)
})
isDowned.subscribe(function(downed){
  if (downed)
    showArtilleryMap(false)
})

isRadioMode.subscribe(@(active) showArtilleryMap(active))

showArtilleryMap.subscribe(function(val){
  if (val) {
    closeMenu("BigMap")
    addInteractiveElement("artilleryMap")
  } else
    removeInteractiveElement("artilleryMap")
})

local function onSelect(pos){
  ::ecs.g_entity_mgr.sendEvent(get_controlled_hero(), ::ecs.event.EventArtilleryMapPosSelected({pos=pos}))
}
local function closeRequest() {
  ::ecs.g_entity_mgr.sendEvent(get_controlled_hero(), ::ecs.event.RequestCloseArtilleryMap())
}

local minimapState = ::MinimapState({
  ctx = mmContext
  visibleRadius = 350
  shape = "square"
})

local mapTransform = { rotate = 90 }
local markersTransform = {rotate = -90}

local visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
}

local mapRootAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

local function mouseTips() {
  local children = [
    mkTips(["LMB"], tipLmb)
    mouseNavTips
  ]
  return {
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(10)
    children = children
  }
}
local titleHint = {
  padding = sh(0.5)
  children = hintTextFunc(::loc(title), DEFAULT_TEXT_COLOR)
  rendObj = ROBJ_WORLD_BLUR_PANEL
  halign = ALIGN_CENTER
}

local tipsBlock = @(){
  size = [flex(), SIZE_TO_CONTENT]
  watch = [isGamepad]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = sh(1)
  children = isGamepad.value ? navGamepadHints : mouseTips
}

local framedMapBg = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = Color(140,140,140,255)
  padding = sh(1)
  hooks = HOOK_ATTACH
  actionSet = "BigMap"
}

local interactiveFrame = @() {
  rendObj = ROBJ_FRAME
  size = flex()
  borderWidth = ::hdpx(2)
  color = Color(180,160,10,130)

  childen = {
    // use frame since parent already has another hook
    hooks = HOOK_ATTACH
    actionSet = "StopInput"
  }
}

local closeMapDesc = {
  action = @() closeRequest(),
  description = ::loc("Close"),
  inputPassive = true
}

local mkMapLayer = @(ctorWatch, paramsWatch) @() {
  watch = [ctorWatch, paramsWatch]
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  clipChildren = true
  eventPassThrough = true
  minimapState = minimapState
  transform = mapTransform
  behavior = Behaviors.Minimap
  children = ctorWatch.value.ctor(paramsWatch.value)
}

local markersParams = ::Computed(@() {
  state = minimapState
  size = mapSize.value
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = true
  showHero = true
})

local function getWorldPos(event, state) {
  local rect = event.targetRect
  local elemW = rect.r - rect.l
  local elemH = rect.b - rect.t
  local relX = (event.screenX - rect.l - elemW*0.5) * 2 / elemW
  local relY = (event.screenY - rect.t - elemH*0.5) * 2 / elemH
  return state.mapToWorld(relY, relX)
}

local function command(event, state) {
  if (event.button == 1)
    closeRequest()
  if (event.button == 0 || isGamepad.value)
    onSelect(getWorldPos(event, state))
}

showArtilleryMap.subscribe(function(show) {
  if (show) {
    sound_play("ui/radio_artillery")
    ::ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdHeroSpeech("artStrikeOrder"))
  }
})

local baseMap = @() {
  size = flex()
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

  onClick = @(e) command(e, minimapState)
}

local framedMap = @() framedMapBg.__merge({
  watch = [mmChildrensCtors, mapSize]
  size = mapSize.value
  children = [
    baseMap
  ]
    .extend(mmChildrensCtors.value.map(@(c) mkMapLayer(c, markersParams)))
    .append(interactiveFrame)
})

local mapBlock = @(){
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    titleHint
    framedMap
    tipsBlock
  ]
}

local function artilleryMap() {
  return {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    watch = mapSize
    cursor = cursors.target
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }

    children = mapBlock

    animations = mapRootAnims
    hotkeys = [
      [ "Esc", closeMapDesc],
      [ "^{0}".subst(JB.B), closeMapDesc],
      [ "@HUD.BigMap", closeMapDesc ],
    ]
  }
}

::ecs.register_es("artilllery_map_ui_es",
  {
    [::ecs.sqEvents.CmdOpenArtilleryMap] = @(...) showArtilleryMap(true),
    [::ecs.sqEvents.CmdCloseArtilleryMap] = @(...) showArtilleryMap(false)
  },
  {
    comps_rq = [
      ["human_weap.radioMode", ::ecs.TYPE_BOOL],
      ["squad_member.squad", ::ecs.TYPE_EID],
    ]
  },
  {tags = "gameClient"}
)

return {
  artilleryMap
  showArtilleryMap
}
 