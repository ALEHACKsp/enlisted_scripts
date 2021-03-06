local {configs} = require("enlisted/enlist/configs/configs.nut")

local gameProfile = ::Computed(@() configs.value?.gameProfile ?? {})
local allArmiesInfo = ::Computed(function() {
  local res = {}
  foreach(c in gameProfile.value?.campaigns ?? {})
    foreach(a in c?.armies ?? {})
      res[a.id] <- a
  return res
})

return {
  gameProfile = gameProfile
  availableCampaigns = ::Computed(@() gameProfile.value?.availableCampaigns ?? [])
  visibleCampaigns = ::Computed(@() gameProfile.value?.visibleCampaigns ?? [])

  allArmiesInfo = allArmiesInfo
} 