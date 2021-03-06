local health = require("health.ui.nut")
local breath = require("breath.ui.nut")
local stamina = require("stamina.ui.nut")

return {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = sh(0.2)
  children = [
    health, stamina, breath
  ]
}
 