local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { curCampaign } = require("enlisted/enlist/meta/curCampaign.nut")
local { hasCampaignSelection }  = require("campaign_sel_state.nut")

local text = @(text) {
  rendObj = ROBJ_DTEXT
  font = Fonts.medium_text
  color = Color(128,128,128,128)

  fontFxColor = 0xFF000000
  fontFxFactor = 16
  fontFx = FFT_GLOW
  fontFxOffsX = 1
  fontFxOffsY = 1

  text = text
}
local function campaignInfo() {
  local campaign = curCampaign.value
  return {
    watch = [curCampaign, gameProfile, hasCampaignSelection]
    children = [
      hasCampaignSelection.value
        ? text(::loc(gameProfile.value?.campaigns[campaign].title ?? campaign))
        : null
    ]
  }
}

return campaignInfo
 