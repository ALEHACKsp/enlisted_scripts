local {setInteractiveElement} = require("ui/hud/state/interactive_state.nut")
local mkPieMenu = require("ui/hud/components/mkPieMenu.nut")
local { showBuildingToolMenu, curBuildingToolMenuItems, radius, elemSize, openBuildingToolMenuPath, buildingToolMenuPath } = require("ui/hud/state/building_tool_menu_state.nut")

showBuildingToolMenu.subscribe(@(val) setInteractiveElement("BuildingToolMenu", val))

local buildingToolMenu = mkPieMenu({
  actions = curBuildingToolMenuItems,
  actionOnDetach = false,
  showPieMenu = showBuildingToolMenu
  radius = radius,
  elemSize = elemSize,
  close = @() openBuildingToolMenuPath.value.len() >= buildingToolMenuPath.value.len() ? showBuildingToolMenu(false)
    : buildingToolMenuPath(@(p) p.remove(p.len() - 1))
})

return {
  size = flex()
  children = buildingToolMenu
  key = "buildMenuMenuTabs"
}
 