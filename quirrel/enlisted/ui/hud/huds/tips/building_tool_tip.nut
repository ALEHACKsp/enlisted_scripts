local { isBuildingToolMenuAvailable, canDismantleSelected, buildingPreviewId, availableBuildings } = require("ui/hud/state/building_tool_state.nut")
local {isRadioMode} = require("enlisted/ui/hud/state/enlisted_hero_state.nut")
local {isMortarMode} = require("common_shooter/ui/hud/state/mortar.nut")
local {isAlive, isDowned} = require("ui/hud/state/hero_state_es.nut")
local { inVehicle } = require("ui/hud/state/vehicle_state.nut")
local { showBuildingToolMenu } = require("ui/hud/state/building_tool_menu_state.nut")
local {tipCmp} = require("ui/hud/huds/tips/tipComponent.nut")
local { DEFAULT_TEXT_COLOR, FAIL_TEXT_COLOR } = require("ui/hud/style.nut")

local function notAbleBuildStructures() {
  local res = { watch = [canDismantleSelected, buildingPreviewId, availableBuildings, isBuildingToolMenuAvailable] }
  if (!isBuildingToolMenuAvailable.value || canDismantleSelected.value)
    return res
  if ((availableBuildings.value?[buildingPreviewId.value] ?? -1) != 0)
    return res
  return res.__update({
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = tipCmp({
      text = ::loc("building_blocked_by_no_available_buildings_by_type", "Cant build anymore")
      textColor = FAIL_TEXT_COLOR
    })
  })
}

local function buildStructure() {
  local res = { watch = [isBuildingToolMenuAvailable, showBuildingToolMenu] }
  if (!isBuildingToolMenuAvailable.value || showBuildingToolMenu.value)
    return res
  return res.__update({
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      tipCmp({
        text = loc("hud/build_building", "Build structure")
        inputId = "Human.Shoot"
        textColor = DEFAULT_TEXT_COLOR
      }),
      tipCmp({
        text = loc("tips/open_building_menu", "Select structure")
        inputId = "HUD.BuildingToolMenu"
        textColor = DEFAULT_TEXT_COLOR
      })
    ]
  })
}

local function destroyStructure() {
  local res = { watch = [canDismantleSelected, inVehicle, isAlive, isDowned, isMortarMode, isRadioMode] }
  if (!canDismantleSelected.value || inVehicle.value || !isAlive.value || isDowned.value || isMortarMode.value || isRadioMode.value)
    return res
  return res.__update({
    children = tipCmp({
      text = loc("hud/destroy_building", "Destroy structure")
      inputId = "Human.BuildingAction"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

return [
  notAbleBuildStructures
  buildStructure
  destroyStructure
]
 