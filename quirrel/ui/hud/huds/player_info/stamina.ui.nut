local {stamina, staminaAnimTrigger} = require("ui/hud/state/stamina_es.nut")
local {scaleStamina} = require("ui/hud/state/hero_state_es.nut")
local {barHeight, barWidth} = require("style.nut")

local staminaAnim = [
  { prop=AnimProp.fgColor, from=Color(255,255,250), to=Color(220,225,100), easing=CosineFull,
    duration=0.5, trigger=staminaAnimTrigger, loop=true
  }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic }
]


local showStamina = ::Computed(@()stamina.value != null && stamina.value<100 && stamina.value>0)

local function staminaComp() {
  local ratio = 0
  local children = null

  local width = barWidth
  if (showStamina.value) {
    ratio = stamina.value / 100.0
    local ir = 1.0-ratio
    local colorBg = Color(30, 30, 50, 40)
    local colorFg = Color(70+ir*170, 80+ir*170, 255-ir*150, 255)
    width *= scaleStamina.value

    children = [
      {
        rendObj = ROBJ_SOLID
        size = [width, barHeight]
        color = colorBg
        halign = ALIGN_RIGHT
        children = {
          rendObj = ROBJ_SOLID
          color = colorFg
          size = [width*ratio,flex()]
        }
        animations = staminaAnim
      }
    ]
  }


  return {
    size = [width, barHeight]
    watch = [stamina, showStamina]
    children = children
  }
}

return staminaComp 