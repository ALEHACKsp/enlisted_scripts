local { radius } = require("ui/hud/state/building_tool_menu_state.nut")
local { availableBuildings, buildingLimits } = require("ui/hud/state/building_tool_state.nut")

local white = Color(255,255,255)
local dark = Color(200,200,200)
local disableColor = Color(60,60,60)
local disabledTextColor = Color(50, 50, 50, 50)
local curTextColor = Color(250,250,200,200)
local defTextColor = Color(150,150,150,50)

return @(buildingIndex, image) @(curIdx, idx) ::watchElemState(function(sf) {
  local count = availableBuildings.value?[buildingIndex] ?? 0
  local limit = buildingLimits.value?[buildingIndex] ?? 0
  local available = count > 0
  local isCurrent = (sf & S_HOVER) || curIdx == idx

  local icon = image ? {
    image = ::Picture(image)
    rendObj = ROBJ_IMAGE
    color = !available ? disableColor : isCurrent ? white : dark
  } : null
  local text = {
    rendObj = ROBJ_DTEXT
    color = !available ? disabledTextColor
              : isCurrent ? curTextColor
              : defTextColor
    text = "{count}/{limit}".subst({count=count limit=limit})
    font = Fonts.medium_text
  }

  return {
    watch = [availableBuildings]
    children = [
      icon
      text
    ]
    size = array(2, (0.4 * radius.value).tointeger())
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
  }
}) 