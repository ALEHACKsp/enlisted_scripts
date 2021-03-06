local {gap, bigPadding, blurBgColor, blurBgFillColor} = require("enlisted/enlist/viewConst.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local {
  curCampaign,
  curArmies } = require("enlisted/enlist/soldiers/model/state.nut")
local campaignsUiComps = require("components/campaignsUiComps.nut")
local armySelect = require("enlisted/enlist/soldiers/army_select.ui.nut")

local borders = safeAreaBorders.value

local isOpened = ::Computed(function() {
  return curCampaign.value != null && curArmies.value?[curCampaign.value] == null
})

local mkChooseArmyBlock = @() {
  watch = curCampaign
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    campaignsUiComps.mkCampaignName(curCampaign.value)
    campaignsUiComps.mkText(::loc("choose_army"))
    { size = [flex(), sh(3)]}
    armySelect({
      hasBackImage = true
      override = {
        size = [sh(44), sh(33)]
        halign = ALIGN_CENTER
        clipChildren = true
        fillColor = Color(0,0,0)
      }
      customGap = bigPadding
      hasHotkeys = false
    })
  ]
}

local chooseArmyScene = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  size = [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  padding = [borders[0], 0, 0, 0]
  children = {
    size = flex()
    flow = FLOW_VERTICAL
    padding = [0, borders[1], borders[2], borders[3]]
    gap = gap
    children = [
      mkChooseArmyBlock
    ]
  }
}

local function open() {
  sceneWithCameraAdd(chooseArmyScene, "armory")
}

if (isOpened.value == true)
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseArmyScene)
})

return isOpened
 