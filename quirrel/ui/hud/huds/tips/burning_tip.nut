local {isBurning} = require("ui/hud/state/burning_state_es.nut")
local {tipCmp} = require("tipComponent.nut")

local color0 = Color(200,40,40,110)
local color1 = Color(200,200,40,180)

local animColor = [
  { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull }
]
local animAppear = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack }]

local tip = tipCmp({
  inputId = "Inventory.UseMedkit"
  text = ::loc("tips/burning_tip")
  textColor = Color(200,40,40,110)
  animations = animAppear
  textAnims = animColor
})

return function() {
  return {
    watch = isBurning
    size = SIZE_TO_CONTENT
    children = !isBurning.value ? null : tip
  }
}

 