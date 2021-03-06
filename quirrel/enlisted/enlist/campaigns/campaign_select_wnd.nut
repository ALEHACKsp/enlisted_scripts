local math = require("std/math.nut")
local style = require("enlisted/enlist/viewConst.nut")
local { safeAreaBorders, safeAreaSize } = require("enlist/options/safeAreaState.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")

local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local { curCampaign, setCurCampaign } = require("enlisted/enlist/meta/curCampaign.nut")
local { availableCampaigns, visibleCampaigns
} = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local campaignsUiComps = require("components/campaignsUiComps.nut")

local isOpened = persist("isOpened", @() Watched(false))

const SHAKE_TEXT_ID = "SHAKE_TEXT_ID"
const TOTAL_ROWS = 2

local campPerRow = ::Computed(@() ::max(1, math.ceil(visibleCampaigns.value.len().tofloat() / TOTAL_ROWS).tointeger()))
local imgHeight = ::Computed(@() min(((min(safeAreaSize.value[1], sh(90)) - (TOTAL_ROWS + 1) * style.bigPadding) / TOTAL_ROWS).tointeger(),
  (((safeAreaSize.value[0] - (campPerRow.value + 1) * style.bigPadding) / campPerRow.value) * 9 / 16).tointeger()))
local imgWidth = ::Computed(@() (imgHeight.value * 16 / 9).tointeger())
local borderSize = hdpx(1)

local campaignSelectWnd = null
local function close() {
  sceneWithCameraRemove(campaignSelectWnd)
  isOpened(false)
}
local function open() {
  close()
  sceneWithCameraAdd(campaignSelectWnd, "armory")
  isOpened(true)
}

local function selectCampaign(campaign) {
  setCurCampaign(campaign)
  close()
}

local shadeBox = { size = flex(), rendObj = ROBJ_SOLID, color = Color(0, 0, 0, 180) }

local function campaignBtn(campaign) {
  local stateFlags = Watched(0)
  local isAvailable = ::Computed(@() availableCampaigns.value.indexof(campaign) != null)
  return @() {
    watch = [isAvailable, imgHeight, imgWidth]
    rendObj = ROBJ_SOLID
    children = [
      campaignsUiComps.mkCampaignImg(campaign, [imgWidth.value, imgHeight.value])
      isAvailable.value ? null : shadeBox
      campaignsUiComps.mkCampaignName(campaign, stateFlags)
      isAvailable.value ? null
        : campaignsUiComps.mkNotAvailableText(campaign, SHAKE_TEXT_ID + campaign, stateFlags)

      function() {
        local sf = stateFlags.value
        return {
          watch = [curCampaign, stateFlags]
          size = flex()
          rendObj = ROBJ_BOX
          sound = {
            hover = "ui/enlist/button_highlight"
            click = "ui/enlist/button_click"
          }
          borderColor = sf & S_HOVER ? style.hoverBgColor : style.defBgColor
          borderWidth = borderSize
          behavior = Behaviors.Button
          onClick = @() isAvailable.value ? selectCampaign(campaign) : anim_start(SHAKE_TEXT_ID + campaign)
          onElemState = @(nsf) stateFlags(nsf)
          fillColor = Color(0,0,0,0)
        }
      }
    ]
  }
}

local mkRows = @(all, perRow) array(min(all.len(), TOTAL_ROWS))
  .map(function(_, rowIdx) {
    local inRowList = all.slice(rowIdx * perRow, min((rowIdx + 1) * perRow, all.len()))
    return {
      flow = FLOW_HORIZONTAL
      gap = style.bigPadding
      children = inRowList.map(campaignBtn)
    }
  })

local campaignSelect = @() {
  watch = [safeAreaBorders, visibleCampaigns, campPerRow]
  margin = safeAreaBorders.value
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  halign = ALIGN_LEFT
  gap = style.bigPadding
  children = mkRows(visibleCampaigns.value, campPerRow.value)

  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
    { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  ]
}

local closeBtnOffset = max(safeAreaBorders.value[0], safeAreaBorders.value[1])
local closeBtn = closeBtnBase({
  onClick = close
}).__update({ margin = closeBtnOffset })

campaignSelectWnd = {
  size = flex()
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = style.blurBgColor
  fillColor = style.blurBgFillColor
  children = [
    closeBtn
    campaignSelect
  ]
}

if (isOpened.value)
  open()

return {
  open = open
  close = close
} 