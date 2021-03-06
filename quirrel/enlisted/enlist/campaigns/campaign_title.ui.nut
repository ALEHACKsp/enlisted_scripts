local style = require("enlisted/enlist/viewConst.nut")
local msgbox = require("enlist/components/msgbox.nut")
local { progressBar } = require("enlisted/enlist/components/defcomps.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local campaignSelectWnd = require("campaign_select_wnd.nut")
local { curCampaign, canChangeCampaign } = require("enlisted/enlist/meta/curCampaign.nut")
local { hasCampaignSelection }  = require("campaign_sel_state.nut")

local {
  curArmyLevel, curArmyExp, curArmyLevels
} = require("enlisted/enlist/soldiers/model/armyUnlocksState.nut")

local mkStateFlagsColor = @(sf)
  sf & S_ACTIVE ? style.activeTitleTxtColor
    : sf & S_HOVER ? style.hoverTitleTxtColor
    : style.titleTxtColor

local text = @(text, sfColor, customStyle = {}) {
  rendObj = ROBJ_DTEXT
  font = Fonts.big_text
  color = sfColor

  fontFxColor = 0xFF000000
  fontFxFactor = 16
  fontFx = FFT_GLOW
  fontFxOffsX = 1
  fontFxOffsY = 1

  text = text
}.__update(customStyle)

local stateFlags = Watched(0)
local function campaignInfo() {
  local curLevel = curArmyLevel.value
  local expToNextLevel = curArmyLevels.value?[curLevel].expSize ?? 0
  local percent = expToNextLevel > 0
    ? (curArmyExp.value).tofloat() / expToNextLevel : 0
  local campaign = curCampaign.value
  local sfColor = mkStateFlagsColor(stateFlags.value)

  return {
    watch = [gameProfile, curCampaign, curArmyLevel, curArmyExp, curArmyLevels, stateFlags, hasCampaignSelection]
    flow = FLOW_VERTICAL
    behavior = hasCampaignSelection.value ? Behaviors.Button : null
    skipDirPadNav = true
    onElemState = @(sf) stateFlags(sf)
    onClick = @() canChangeCampaign.value ? campaignSelectWnd.open()
      : msgbox.show({ text = ::loc("Only squad leader can change params") })
    children = [
      text(::loc(gameProfile.value?.campaigns[campaign].title ?? campaign), sfColor)
      text(::loc("levelInfo", { level = curLevel }),
        sfColor, {font = Fonts.small_text})
      progressBar({ value = percent, color = sfColor })
    ]
  }
}

return campaignInfo
 