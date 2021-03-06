local { rewardedSingleMissons } = require("enlisted/enlist/meta/profile.nut")
local { lastGameTutorialId } = require("enlisted/enlist/tutorial/battleTutorial.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local sharedWatched = require("globals/sharedWatched.nut")

local singleMissionRewardId = keepref(::Computed(function() {
  local id = lastGameTutorialId.value
  if (id == null || (rewardedSingleMissons.value?[id].version ?? 0) >= (gameProfile.value?.tutorials[id].version ?? 0))
    return null
  return id
}))

local singleMissionRewardIdShared = sharedWatched("singleMissionRewardId", @() singleMissionRewardId.value)
singleMissionRewardIdShared(singleMissionRewardId.value)
singleMissionRewardId.subscribe(@(v) singleMissionRewardIdShared(v))

local singleMissionRewardSum = keepref(::Computed(@()
  gameProfile.value?.tutorials[singleMissionRewardId.value].expSum ?? 0))

local singleMissionRewardSumShared = sharedWatched("singleMissionRewardSum", @() singleMissionRewardSum.value)
singleMissionRewardSumShared(singleMissionRewardSum.value)
singleMissionRewardSum.subscribe(@(v) singleMissionRewardSumShared(v)) 