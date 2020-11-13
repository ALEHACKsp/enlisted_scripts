local minimapCtor = require("ui/hud/huds/minimap/minimap.nut")
local mouseButtons = require("globals/mouse_buttons.nut")

return {
  minimap = @() minimapCtor({panButton = mouseButtons.MMB})
}
 