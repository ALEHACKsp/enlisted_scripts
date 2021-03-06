local {setInteractiveElement} = require("ui/hud/state/interactive_state.nut")
local mkPieMenu = require("ui/hud/components/mkPieMenu.nut")
local { showWallposterMenu, wallposterMenuItems, radius, elemSize } = require("enlisted/ui/hud/state/wallposter_menu.nut")

showWallposterMenu.subscribe(@(val) setInteractiveElement("WallposterMenu", val))

local wallposterMenu = mkPieMenu({
  actions = wallposterMenuItems,
  actionOnDetach = false,
  showPieMenu = showWallposterMenu
  radius = radius,
  elemSize = elemSize,
  close = @() showWallposterMenu(false)
})

return {
  size = flex()
  children = wallposterMenu
  key = "wallposterMenuMenuTabs"
}
 