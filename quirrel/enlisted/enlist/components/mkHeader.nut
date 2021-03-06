local { navHeight } = require("enlisted/enlist/mainMenu/mainmenu.style.nut")
local { windowsInterval } = require("enlisted/enlist/viewConst.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { sceneHeaderText } = require("enlisted/enlist/components/defcomps.nut")
local { mkIcon } = require("enlisted/enlist/soldiers/components/armyPackage.nut")
local borders = safeAreaBorders.value

local mkHeader = @(armyId, textLocId = "", closeButton = null, addToRight = null) @(){
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [flex(), navHeight]
  flow = FLOW_HORIZONTAL
  gap = sh(1)
  valign = ALIGN_CENTER
  margin = [0, 0, windowsInterval]
  padding = [0, borders[1], 0, borders[3]]
  children = [
    mkIcon(armyId, ::hdpx(46))
    textLocId.len() > 0 ? sceneHeaderText(::loc(textLocId)) : null
    { size = flex() }
    addToRight
    closeButton
  ]
}

return ::kwarg(mkHeader)
 