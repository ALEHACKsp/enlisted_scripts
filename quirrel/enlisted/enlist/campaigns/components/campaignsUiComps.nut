local style = require("enlisted/enlist/viewConst.nut")
local model = require("enlisted/enlist/soldiers/model/state.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")


local mkText = @(text, color = style.titleTxtColor) {
  rendObj = ROBJ_DTEXT
  font = Fonts.big_text
  color = color
  margin = [style.bigPadding - hdpx(5) /*font offset*/, style.bigPadding]

  fontFxColor = 0xFF000000
  fontFxFactor = 16
  fontFx = FFT_GLOW
  fontFxOffsX = 1
  fontFxOffsY = 1

  text = text
}

local mkCampaignImg = @(campaign, size) {
  size = size
  rendObj = ROBJ_IMAGE
  image = ::Picture($"ui/gameImage/{campaign}.jpg")
}

local mkCampaignName = @(campaign, stateFlags = Watched(0)) @() {
  watch = [stateFlags, gameProfile]
  children = mkText(::loc(gameProfile.value?.campaigns[campaign]?.title ?? campaign),
    model.curCampaign.value == campaign ? style.titleTxtColor
      : stateFlags.value & S_HOVER ? style.hoverTitleTxtColor
      : style.activeTitleTxtColor
  )
}

local mkNotAvailableText = @(campaign, triggerId, stateFlags) {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  transform = {}
  animations = [{ trigger = triggerId, prop = AnimProp.translate,
    from = [-hdpx(20), 0], to = [0, 0], play = false, duration = 1, easing = OutElastic }]

  children = @() {
    watch = stateFlags
    children = mkText(::loc("campaign/notAvailable"),
      stateFlags.value & S_HOVER ? style.hoverTitleTxtColor : style.activeTitleTxtColor)
  }
}

return {
  mkText = mkText
  mkCampaignImg = mkCampaignImg
  mkCampaignName = mkCampaignName
  mkNotAvailableText = mkNotAvailableText
} 