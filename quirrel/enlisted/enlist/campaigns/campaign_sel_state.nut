local { visibleCampaigns, availableCampaigns } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { canChangeCampaign } = require("enlisted/enlist/meta/curCampaign.nut")

local hasCampaignSelection = Computed(function(){
  if (!canChangeCampaign.value)
    return false
  local res = []
  foreach (c in visibleCampaigns.value){
    if (availableCampaigns.value.contains(c))
      res.append(c)
  }
  return res.len()>1
})

return {hasCampaignSelection} 