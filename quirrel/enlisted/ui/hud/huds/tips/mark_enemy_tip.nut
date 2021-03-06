local { isAlive } = require("ui/hud/state/hero_state_es.nut")
local { isAiming } = require("ui/hud/huds/crosshair_state_es.nut")
local { tipCmp } = require("ui/hud/huds/tips/tipComponent.nut")

local tip = tipCmp({
  inputId = "HUD.SetMarkEnemy"
  text = ::loc("controls/HUD.SetMarkEnemy")
  textColor = Color(200,140,100,110)
})

local isPreventReloadingVisible = ::Computed(@() isAiming.value && isAlive.value)

return @() {
  watch = isPreventReloadingVisible
  size = SIZE_TO_CONTENT
  children = isPreventReloadingVisible.value ? tip : null
}
 