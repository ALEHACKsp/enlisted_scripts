local client = require("enlisted/enlist/meta/clientApi.nut")

local function remoteGenPerksPointsStatistics(tier, count, genId) {
  client.gen_perks_points_statistics(tier, count, genId, function(stats) {
    log_for_user("Generated perks points for" count "soldiers (of `" tier "tier)")
    foreach (statId, statVal in stats.detail)
      log_for_user("  Detail (min / max):" statVal.min "/" statVal.max
        ", (average):" statVal.sum.tofloat() / count "of '" statId "' stat")

    foreach (statId, statVal in stats.total)
      log_for_user(statVal "soldiers have" statId "points")
  })
}

return {
  genPerksPointsStatistics = remoteGenPerksPointsStatistics
}
 