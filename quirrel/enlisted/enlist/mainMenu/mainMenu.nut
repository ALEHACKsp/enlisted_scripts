local {lerp} = require("std/math.nut")

local { safeAreaAmount, safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { sectionsSorted, curSection } = require("sectionsState.nut")
local bottomBar = require("bottomRightButtons.nut")

local { navHeader } = require("sections.nut")

local { gap } = require("enlisted/enlist/viewConst.nut")


local sectionsAnimation = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
]

local sectionContent = @() {
  watch = [curSection, sectionsSorted] //animations does not restart when parent not changed
  size = flex()
  children = {
    size = flex()
    children = (sectionsSorted.value ?? []).findvalue(@(val) val?.id == curSection.value)?.content
    key = curSection.value
    transform = {}
    animations = sectionsAnimation
  }
}

local lerp_bottom_margin = @(v) lerp(0.9, 1.0, 1.15, 1, v)
local function mainMenu() {
  local borders = safeAreaBorders.value
  return {
    watch = safeAreaBorders
    size = [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    padding = [borders[0], 0, 0, 0]
    children = [
      navHeader
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [0, borders[1], borders[2]*lerp_bottom_margin(safeAreaAmount.value), borders[3]]
        gap = gap
        children = [
          sectionContent
          bottomBar
        ]
      }
    ]
  }
}

return mainMenu
 