local { radius } = require("enlisted/ui/hud/state/wallposter_menu.nut")

local white = Color(255,255,255)
local dark = Color(200,200,200)
local curTextColor = Color(250,250,200,200)
local defTextColor = Color(150,150,150,50)

return @(buildingIndex, image, hintText) @(curIdx, idx) ::watchElemState(function(sf) {
  local isCurrent = (sf & S_HOVER) || curIdx == idx

  local icon = image ? {
    image = ::Picture(image)
    rendObj = ROBJ_IMAGE
    color = isCurrent ? white : dark
  } : null
  local text = {
    rendObj = ROBJ_DTEXT
    color = isCurrent ? curTextColor : defTextColor
    text = hintText
    font = Fonts.small_text
  }

  return {
    children = [
      icon
      text
    ]
    size = array(2, (0.4 * radius.value).tointeger())
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
  }
}) 