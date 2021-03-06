local { curWeapon } = require("ui/hud/state/hero_state.nut")
local {isAlive, isDowned} = require("ui/hud/state/hero_state_es.nut")
local {inVehicle} = require("ui/hud/state/vehicle_state.nut")
local isMachinegunner = require("ui/hud/state/machinegunner_state.nut")

local buildingTemplates = persist("buildingTemplates", @() ::Watched([]))
local availableBuildings = persist("availableBuildings", @() :: Watched([]))
local buildingLimits = persist("buildingLimits", @() :: Watched([]))
local isBuildingToolEquipped = ::Computed(@() curWeapon.value?.weapType =="building_tool")
local isBuildingToolMenuAvailable = ::Computed(@() isBuildingToolEquipped.value && isAlive.value && !isDowned.value && !inVehicle.value && !isMachinegunner.value)
local canDismantleSelected = persist("canDismantleSelected", @() ::Watched(false))
local buildingPreviewId = persist("buildingPreviewId", @() ::Watched(null))

local buildTemplatesQuery = ::ecs.SqQuery("buildTemplatesQuery", {comps_ro=["human_weap.currentGunEid"], comps_rq=["hero"]})

isBuildingToolEquipped.subscribe(function (isEquipped) {
  if (!isEquipped)
    return
  buildTemplatesQuery.perform(function(eid, comp) {
    local toolEid = comp["human_weap.currentGunEid"]
    local templates = ::ecs.get_comp_val(toolEid, "previewTemplate", null)?.getAll() ?? []
    local limits = ::ecs.get_comp_val(toolEid, "buildingLimits", null)?.getAll() ?? []
    buildingTemplates(templates)
    buildingLimits(limits)
  })
})

::ecs.register_es("ui_building_selected_object_es",
  {
    [["onChange", "onInit"]] = function (evt, eid, comp) {
      local selectedObject = comp["human_use_object.selectedObject"]
      local currentGunEid = comp["human_weap.currentGunEid"]
      local currentPreviewId = ::ecs.get_comp_val(currentGunEid, "currentPreviewId", null);
      buildingPreviewId(currentPreviewId)
      canDismantleSelected(::ecs.get_comp_val(selectedObject, "buildByPlayer", null) != null)
    },
  },
  {
    comps_track = [["human_use_object.selectedObject", ::ecs.TYPE_EID]],
    comps_ro = [["human_weap.currentGunEid", ::ecs.TYPE_EID]],
    comps_rq = ["hero"]
  }
)

::ecs.register_es("ui_available_buildings_es",
  {
    [["onChange", "onInit"]] = function(evt, eid, comp) {
      if (comp.is_local)
        availableBuildings(comp.availableBuildings.getAll() ?? [])
    }
  },
  {
    comps_ro=[["is_local", ::ecs.TYPE_BOOL]]
    comps_track = [["availableBuildings", ::ecs.TYPE_INT_LIST]],
    comps_rq = ["player"]
  }
)

return {
  buildingTemplates = buildingTemplates
  isBuildingToolEquipped = isBuildingToolEquipped
  isBuildingToolMenuAvailable = isBuildingToolMenuAvailable
  canDismantleSelected = canDismantleSelected
  buildingPreviewId = buildingPreviewId
  availableBuildings = availableBuildings
  buildingLimits = buildingLimits
}
 