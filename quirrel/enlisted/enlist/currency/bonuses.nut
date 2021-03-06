local { boughtBonuses } = require("enlisted/enlist/meta/clientApi.nut").profile
local { configs } = require("enlisted/enlist/configs/configs.nut")

local bonusesList = ::Computed(@()
  configs.value?.game_bonuses ?? {})

local curBonusesEffects = ::Computed(function() {
  local res = {}
  foreach (bonus in boughtBonuses.value)
    foreach (bonusId, effect in bonusesList.value?[bonus.guid].effects ?? {})
      res[bonusId] <- (res?[bonusId] ?? 0) + effect

  return res
})

return {
  bonusesList = bonusesList
  curBonuses = boughtBonuses
  curBonusesEffects = curBonusesEffects
}
 