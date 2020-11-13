local {isGamepad} = require("ui/control/active_controls.nut")
local {safeAreaBorders} = require("enlist/options/safeAreaState.nut")
local tooltipBox = require("tooltipBox.nut")
local platform = require("globals/platform.nut")
local colors = require("ui/style/colors.nut")
local cursors = {}
local {cursorOverScroll, cursorOverClickable} = ::gui_scene
local showGamepad = ::Computed(@() isGamepad.value || platform.is_xbox || platform.is_sony || platform.is_nswitch)
local hideCursor = platform.is_android
cursors.tooltip <- {
  state = Watched(null)
}

local colorBack = Color(0,0,0,120)

local mkTooltipCmp = @(align) @(){
  key = "tooltip"
  pos = align == ALIGN_BOTTOM ? [0, 0]
    : showGamepad.value ? [hdpx(28), hdpx(40)]
    : [hdpx(12), hdpx(28)]
  watch = [cursors.tooltip.state, showGamepad]
  behavior = Behaviors.BoundToArea
  transform = {}
  safeAreaMargin = safeAreaBorders.value
  vplace = align
  children = typeof cursors.tooltip.state.value == "string"
  ? tooltipBox({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(500)
      text = cursors.tooltip.state.value
      color = Color(180, 180, 180, 120)
    })
  : cursors.tooltip.state.value
}

cursors.tooltip.cmp <- mkTooltipCmp(ALIGN_TOP)
cursors.tooltip.cmpTop <- mkTooltipCmp(ALIGN_BOTTOM)

//EXAMPLE: CUSTOM TOOLTIP (MAY BE FUNCTION OR TABLE)
/*    function onHover(on) {
        cursors.tooltip.state(
          on && descLoc != ""
          ? {
              rendObj = ROBJ_DTEXT
              text = descLoc
              fontFx = FFT_GLOW
              fontFxColor = Color(0, 0, 0, 120)
              fontFxFactor = 50
              transform = {}
              safeAreaMargin = [sh(2), sh(2)]
            }
          : null
        )
      }
 */

local getEvenIntegerHdpx = @(px) ::hdpx(0.5 * px).tointeger() * 2

local scroll_size = getEvenIntegerHdpx(20)

local round_cursor = [
  [VECTOR_WIDTH, hdpx(1.4)],
  [VECTOR_FILL_COLOR, Color(70, 80, 90, 90)],
  [VECTOR_COLOR, Color(100, 100, 100, 50)],
  [VECTOR_ELLIPSE, 50, 50, 50, 50],
  [VECTOR_WIDTH, hdpx(1.5)],
  [VECTOR_FILL_COLOR, 0],
  [VECTOR_COLOR, Color(0, 0, 0, 60)],
  [VECTOR_ELLIPSE, 50, 50, 43, 43],
  [VECTOR_WIDTH, hdpx(1.5)],
  [VECTOR_COLOR, Color(100, 100, 100, 50)],
  [VECTOR_ELLIPSE, 50, 50, 46, 46],
]

local joyScrollCursorImage = {
  key = "scroll-cursor"
  rendObj = ROBJ_IMAGE
  size = [scroll_size, scroll_size]
  image = ::Picture($"!ui/uiskin/cursor_scroll.svg:{scroll_size}:{scroll_size}:K")
  keepAspect = true
  pos = [hdpx(20), hdpx(30)]
  opacity = 1

  transform = {}

  animations = [
    { prop=AnimProp.opacity,  from=0.0,    to=1.0,     duration=0.3,  play=true, easing=OutCubic }
    { prop=AnimProp.opacity,  from=1.0,    to=0.0,     duration=0.1,  playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.scale,    from=[0, 0], to=[1, 1],  duration=0.15, play=true, easing=OutCubic }
    { prop=AnimProp.scale,    from=[1, 1], to=[0, 0],  duration=0.1,  playFadeOut=true, easing=OutCubic }
  ]
}

local cursorSzNormal     = getEvenIntegerHdpx(32)
local cursorSzResizeDiag = getEvenIntegerHdpx(18)

local normalCursorPic = ::Picture("!ui/skin#cursor.svg:{0}:{0}:K".subst(cursorSzNormal))

local draggableCursorPic = ::Picture("!ui/skin#hand.svg:{0}:{0}:K".subst(cursorSzNormal))

local targetCursorPic = ::Picture("!ui/skin#sniper_rifle.svg:{0}:{0}:K".subst(cursorSzNormal))
local cursorImageComp = {
  rendObj = ROBJ_IMAGE
  image = normalCursorPic
  size = [cursorSzNormal, cursorSzNormal]
}

local function mkPcCursor(children){
  children = children ?? []
  if (::type(children) != "array")
    children = [children]
  children = clone children
  children.append(cursorImageComp)
  return {
    size = [0, 0]
    children = children
    watch = [showGamepad, cursorOverScroll]
  }
}

local gamepadCursorSize = [hdpx(40), hdpx(40)]

local gamepadOnClickAnimationComp = {
  animations = [
    {prop=AnimProp.scale, from=[0.5, 0.5], to=[1, 1],  duration=0.5, play=true, loop=true }
  ]
  commands = round_cursor
  rendObj = ROBJ_VECTOR_CANVAS
  size = gamepadCursorSize
  halign = ALIGN_CENTER
  transform = {pivot=[0.5,0.5]}
  opacity = 0.5
}

local gamepadComp = {
  rendObj = ROBJ_VECTOR_CANVAS
  size = gamepadCursorSize
  commands = round_cursor
}

local function mkGamepadCursor(children){
  children = clone children
  children.append(gamepadComp)
  if (cursorOverClickable.value)
    children.append(gamepadOnClickAnimationComp)
  return {
    hotspot = [::hdpx(20), ::hdpx(20)]
    watch = [showGamepad, cursorOverScroll, cursorOverClickable]
    size = gamepadCursorSize
    children = children
    halign = ALIGN_CENTER
    transform = {
      pivot = [0.5, 0.5]
    }
  }
}

local function mkHiddenCursor(children){
  return {
    children = children
  }
}

local function mkCursorWithTooltip(children){
  if (::type(children) != "array")
    children = [children]
  if (cursorOverScroll.value && showGamepad.value)
    children.append(joyScrollCursorImage)
  return showGamepad.value ? mkGamepadCursor(children)
                           : hideCursor ? mkHiddenCursor(children)
                           : mkPcCursor(children)
}

cursors.normal <- ::Cursor(@() mkCursorWithTooltip(cursors.tooltip.cmp))

cursors.normalTooltipTop <- ::Cursor(@() mkCursorWithTooltip(cursors.tooltip.cmpTop))

cursors.target <- ::Cursor(function() {
  local children = [cursors.tooltip.cmp]
  return {
    rendObj = ROBJ_IMAGE
    size = [cursorSzNormal, cursorSzNormal]
    hotspot = [cursorSzNormal/2, cursorSzNormal/2]
    image = targetCursorPic
    children = children
    watch = [showGamepad, cursorOverScroll]
    transform = {
      pivot = [0, 0]
    }
  }
})

cursors.draggable <- ::Cursor(function() {
  local children = [cursors.tooltip.cmp]
  if (cursorOverScroll.value && showGamepad.value)
    children.append(joyScrollCursorImage)
  return showGamepad.value
    ? mkGamepadCursor(children)
    : {
        rendObj = ROBJ_IMAGE
        size = [cursorSzNormal, cursorSzNormal]
        hotspot = [0, 0]
        image = draggableCursorPic
        children = children
        watch = [showGamepad, cursorOverScroll]
        transform = {
        pivot = [0, 0]
      }
  }
})

local helpSign = {rendObj = ROBJ_STEXT text = "?" fontSize = ::hdpx(25) vplace = ALIGN_CENTER fontFx = FFT_GLOW fontFxFactor=48 fontFxColor = colorBack color = colors.Black}
local helpSignPc = helpSign.__merge({pos = [::hdpx(25), ::hdpx(10)]})

cursors.help <- ::Cursor(function(){
  local children = [
    cursorOverScroll.value && showGamepad.value
      ? joyScrollCursorImage : null,
    showGamepad.value ? helpSign
                      : hideCursor ? null
                      : helpSignPc,
    cursors.tooltip.cmp
  ]
  return showGamepad.value ? mkGamepadCursor(children)
                           : hideCursor ? mkHiddenCursor(children)
                           : mkPcCursor(children)
})

local function mkResizeC(commands, angle=0){
  return {
    rendObj = ROBJ_VECTOR_CANVAS
    size = [cursorSzResizeDiag, cursorSzResizeDiag]
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_FILL_COLOR, Color(255,255,255)],
      [VECTOR_COLOR, Color(20, 40, 70, 250)],
      [VECTOR_POLY].extend(commands.map(@(v) v.tofloat()*100/7.0))
    ]
    hotspot = [cursorSzResizeDiag / 2, cursorSzResizeDiag / 2]
    transform = {rotate=angle}
  }
}
local horArrow = [0,3, 2,0, 2,2, 5,2, 5,0, 7,3, 5,6, 5,4, 2,4, 2,6]
cursors.sizeH <- ::Cursor(mkResizeC(horArrow))
cursors.sizeV <- ::Cursor(mkResizeC(horArrow, 90))
cursors.sizeDiagLtRb <- ::Cursor(mkResizeC(horArrow, 45))
cursors.sizeDiagRtLb <- ::Cursor(mkResizeC(horArrow, 135))

cursors.moveResizeCursors <- {
  [MR_LT] = cursors.sizeDiagLtRb,
  [MR_RB] = cursors.sizeDiagLtRb,
  [MR_LB] = cursors.sizeDiagRtLb,
  [MR_RT] = cursors.sizeDiagRtLb,
  [MR_T]  = cursors.sizeV,
  [MR_B]  = cursors.sizeV,
  [MR_L]  = cursors.sizeH,
  [MR_R]  = cursors.sizeH,
}

cursors.normalCursorPic <- normalCursorPic

cursors.withTooltip <- function(comp, tooltip) {
  local function applyTooltip(comp, tooltip) {
    // do not attract dirpad to tooltip components by default
    local { behavior = [], onHover = null, skipDirPadNav = true, eventPassThrough = true } = comp
    behavior = typeof behavior != "array" ? [behavior] : behavior
    if (!behavior.contains(Behaviors.Button))
      behavior.append(Behaviors.Button)
    local onHoverNew = function(on) {
      cursors.tooltip.state(on ? tooltip : null)
      onHover?(on)
    }
    return (comp ?? {}).__merge({
      behavior
      skipDirPadNav
      eventPassThrough
      onHover = onHoverNew
      inputPassive = true
    })
  }
  return typeof comp == "table"
    ? applyTooltip(comp, tooltip)
    : @() applyTooltip(comp?(), tooltip)
}

return cursors
 