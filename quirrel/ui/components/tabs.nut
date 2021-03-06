local tabsBase = require("daRg/components/tabs.nut")
local colors = require("ui/style/colors.nut")
local tabCtor = require("tabCtor.nut")

local function tabsHolder(params) {
  return {
    rendObj = ROBJ_BOX
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    padding = [0, hdpx(3)]
    gap = hdpx(3)

    fillColor = colors.ControlBgOpaque
    borderColor = Color(100, 100, 100, 120)
    borderWidth = [0, 0, 1, 0]
  }
}


return tabsBase(tabsHolder, tabCtor)
 