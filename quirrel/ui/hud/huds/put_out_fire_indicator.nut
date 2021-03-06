local burningState = require("ui/hud/state/burning.nut")
local fa = require("daRg/components/fontawesome.map.nut")

local putOutProgress = ::Computed(function() {
  local { force, maxForce, isPuttingOut } = burningState.value
  if (!isPuttingOut || force <= 0.0 || maxForce <= 0.0)
    return 0.0
  return ::clamp(force / maxForce, 0.0, 0.999)
})

local commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 15, 15, 0.0, 320.0],
]
local sector = commands[1]
local putOutFireProgressSize = [hdpx(300), hdpx(300)]
local putOutFireProgress = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = putOutFireProgressSize
  children = [
    {
      rendObj = ROBJ_STEXT
      font = Fonts.fontawesome
      color = Color(255, 255, 255)
      text = fa["fire"]
      fontSize = hdpx(30)
    }
    {
      size = flex()
      lineWidth = hdpx(4.0)
      color = Color(255, 255, 255)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      behavior = Behaviors.RtPropUpdate
      commands = commands
      update = function() {
        sector[6] = 360.0 * putOutProgress.value
      }
    }
  ]
}

return function() {
  local progress = putOutProgress.value
  return {
    watch = [putOutProgress]
    children = progress > 0.0 ? putOutFireProgress : null
  }
} 