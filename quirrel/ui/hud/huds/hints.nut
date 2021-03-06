local { hints } = require("ui/hud/state/eventlog.nut")

local defTextAnims = [
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
]

local defHintCtor = @(hint) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  font = Fonts.big_text
  halign = ALIGN_CENTER
  text = hint?.text

  sound = "attachSound" in hint ? { attach = { name = hint.attachSound }} : {}

  key = hint
  transform = { pivot = [0, 1] }
  animations = defTextAnims
}

local hintsRoot = @() {
  watch = hints.events
  size   = [sh(100), SIZE_TO_CONTENT]
  flow   = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_TOP

  children = hints.events.value.map(@(hint) hint?.ctor(hint) ?? defHintCtor(hint))
}

return hintsRoot
 