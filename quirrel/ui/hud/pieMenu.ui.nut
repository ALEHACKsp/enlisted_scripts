local {setInteractiveElement} = require("ui/hud/state/interactive_state.nut")
local mkPieMenu = require("components/mkPieMenu.nut")
local { showPieMenu, curPieMenuItems, radius, elemSize, openPieMenuPath, pieMenuPath } = require("state/pie_menu_state.nut")

showPieMenu.subscribe(@(val) setInteractiveElement("pieMenu", val))

local pieMenu = mkPieMenu({
  actions = curPieMenuItems,
  actionOnDetach = false,
  showPieMenu = showPieMenu
  radius = radius,
  elemSize = elemSize,
  close = @() openPieMenuPath.value.len() >= pieMenuPath.value.len() ? showPieMenu(false)
    : pieMenuPath(@(p) p.remove(p.len() - 1))
})

return {
  size = flex()
  children = pieMenu
  key = "pieMenuTabs"
}
 