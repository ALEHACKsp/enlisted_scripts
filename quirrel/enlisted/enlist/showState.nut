local { curCamera } = require("enlisted/enlist/sceneWithCamera.nut")
local { curSoldierGuid } = require("enlisted/enlist/soldiers/model/squadInfoState.nut")
local { curVehicle, objInfoByGuid } = require("enlisted/enlist/soldiers/model/state.nut")
local { viewVehicle } = require("enlisted/enlist/vehicles/vehiclesListState.nut")
local { viewItem } = require("enlisted/enlist/soldiers/model/selectItemState.nut")

local curHoveredItem = persist("curHoveredItem", @() Watched(null))
local curHoveredSoldier = persist("curHoveredSoldier", @() Watched(null))
local curSelectedItem = persist("curSelectedItem", @() Watched(null))

local itemInArmory = ::Computed(function() {
  local item = viewItem.value ?? curSelectedItem.value
  return item?.itemtype != "vehicle" ? item?.gametemplate : null
})

local currentNewItem = ::Computed(@() curSelectedItem.value?.itemtype == "soldier" ? null : curSelectedItem.value?.gametemplate)
local currentNewSoldierGuid = ::Computed(@() curSelectedItem.value?.itemtype == "soldier" ? curSelectedItem.value?.guid : null)

local soldierInSoldiers = ::Computed(@() curCamera.value == "new_items" ? currentNewSoldierGuid.value : curSoldierGuid.value)

local vehicleInVehiclesScene = ::Computed(@()
  curSelectedItem.value?.gametemplate ?? (viewVehicle.value?.gametemplate ?? objInfoByGuid.value?[curVehicle.value].gametemplate))

local function isAircraft(template) {
  if (template == null)
    return false
  local templ = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  return templ?.getCompValNullable("airplane") != null
}

local scene = ::Computed(function() {
  local curCameraValue = curSelectedItem.value?.itemtype == "vehicle" ? "vehicles" : curCamera.value
  return curCameraValue == "soldiers" && !curSoldierGuid.value ? "squad"
    : curCameraValue == "vehicles" && isAircraft(vehicleInVehiclesScene.value) ? "aircrafts"
    : curCameraValue == "new_items" && currentNewSoldierGuid.value ? "soldier_in_middle"
    : curCameraValue
})

return {
  currentNewItem
  curHoveredItem
  curHoveredSoldier
  curSelectedItem
  vehicleInVehiclesScene
  itemInArmory
  soldierInSoldiers
  scene
} 