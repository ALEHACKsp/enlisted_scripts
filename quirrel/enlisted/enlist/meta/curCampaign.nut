local mkOnlineSaveData = require("enlist/options/mkOnlineSaveData.nut")
local { squadLeaderState, isInSquad, isSquadLeader } = require("enlist/squad/squadState.nut")
local { visibleCampaigns, availableCampaigns
} = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")

local curCampaignStorage = mkOnlineSaveData("curCampaign")
local setCurCampaign = curCampaignStorage.setValue
local curCampaignStored = curCampaignStorage.watch
local curCampaign = ::Computed(function() {
  local campaign = (isSquadLeader.value ? null : squadLeaderState.value?.curCampaign) ?? curCampaignStored.value
  if (visibleCampaigns.value.indexof(campaign) == null
      || availableCampaigns.value.indexof(campaign) == null)
    return availableCampaigns.value?[0]
  return campaign
})

return {
  setCurCampaign = setCurCampaign
  curCampaign = curCampaign
  canChangeCampaign = ::Computed(@() !isInSquad.value || isSquadLeader.value)
} 