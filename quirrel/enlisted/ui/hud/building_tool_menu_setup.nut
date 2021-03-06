local { buildingToolMenuItems, showBuildingToolMenu, elemSize } = require("ui/hud/state/building_tool_menu_state.nut")
local { isBuildingToolMenuAvailable, buildingTemplates, availableBuildings } = require("ui/hud/state/building_tool_state.nut")
local mkPieItemCtor = require("enlisted/ui/hud/components/building_tool_menu_item_ctor.nut")
local { playerEvents } = require("ui/hud/state/eventlog.nut")
local { controlledHeroEid } = require("ui/hud/state/hero_state_es.nut")

local showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

local function selectBuildingType(index) {
  local weapEid = ::ecs.get_comp_val(controlledHeroEid.value, "human_weap.currentGunEid", INVALID_ENTITY_ID)
  ::ecs.client_send_event(weapEid, ::ecs.event.CmdSelectBuildingType({index=index}))
}

local svg = @(img) "!ui/uiskin/{0}.svg:{1}:{1}:K".subst(img, elemSize.value[1])

buildingTemplates.subscribe(function (templates){
  buildingToolMenuItems(templates.map(function (templateName, index) {
    local template = ::ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
    local text = template?.getCompValNullable?("building_menu.text") ?? ""
    local imageName = template?.getCompValNullable?("building_menu.image")
    local image = imageName ? svg(imageName) : null
    local buildCount = ::Computed(@() availableBuildings.value?[index] ?? 0)
    local hintText = ::Computed(@() "{text}\n{hint}".subst({text=::loc(text), hint=::loc("buildingMenu/availableCount", {count=buildCount.value})}))
    return {
      action = @() selectBuildingType(index)
      disabledAction = @() showMsg(::loc("msg/buildTypeLimitReached"))
      text = hintText
      disabledtext = ::loc("buildingMenu/buildTypeLimitReached")
      available = ::Computed(@() buildCount.value > 0)
      closeOnClick = true
      ctor = mkPieItemCtor(index, image)
    }
  }))
  if (templates.len() == 0)
    showBuildingToolMenu(false)
})

isBuildingToolMenuAvailable.subscribe(function(isAvailable) { if(!isAvailable) showBuildingToolMenu(false) })
 