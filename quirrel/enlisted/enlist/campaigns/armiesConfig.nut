local {configs} = require("enlisted/enlist/configs/configs.nut")

local armiesUnlocks = ::Computed(@() configs.value?.armies_unlocks ?? [])

local armiesRewards = ::Computed(@()
  armiesUnlocks.value.reduce(function(res, u) {
    local rewardId = u?.rewardInfo.rewardId ?? ""
    if (rewardId == "")
      return res
    local { armyId } = u
    if (armyId not in res)
      res[armyId] <- {}
    if (rewardId not in res[armyId])
      res[armyId][rewardId] <- []
    res[armyId][rewardId].append(u.level)
    return res
  }, {}))

return {
  armyLevelsData = ::Computed(@() configs.value?.army_levels_data ?? [])
  armiesUnlocks
  armiesRewards
}
 