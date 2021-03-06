local {inTank, inPlane} = require("ui/hud/state/vehicle_state.nut")
local {showGameMenu} = require("ui/hud/menus/game_menu.nut")
local {needSpawnMenu} = require("enlisted/ui/hud/state/respawnState.nut")

return {
  isVisible = ::Computed(@() (inTank.value || inPlane.value) && !showGameMenu.value && !needSpawnMenu.value)
} 