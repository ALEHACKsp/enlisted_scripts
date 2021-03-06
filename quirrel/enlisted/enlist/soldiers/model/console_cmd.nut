local { curSoldierGuid } = require("squadInfoState.nut")
local { genPerksPointsStatistics } = require("playerStatistics.nut")
local { resetProfile } = require("state.nut")
local {
  get_all_configs, cheat_premium_add, cheat_premium_remove, add_exp_to_soldiers
} = require("enlisted/enlist/meta/clientApi.nut")
local { selectedSoldierGuid } = require("chooseSoldiersState.nut")

console.register_command(
  function(exp) {
    local guid = selectedSoldierGuid.value ?? curSoldierGuid.value
    if (exp <= 0)
      log_for_user("Unable to substract exp")
    else if (!guid)
      log_for_user("Select soldier in squad list")
    else
      add_exp_to_soldiers({ [guid] = exp }, log_for_user)
  },
  "meta.addCurSoldierExp")

console.register_command(@() resetProfile(), "meta.resetProfile")

console.register_command(function(sTier, count, genId) {
  genPerksPointsStatistics(sTier, count, genId)
}, "stat.perksPoints")

console.register_command(
  function() {
    get_all_configs()
  },
  "meta.getAllConfigs")

console.register_command(function(durationSec) {
  cheat_premium_add(durationSec)
}, "meta.cheatPremiumAdd")

console.register_command(function(durationSec) {
  cheat_premium_remove(durationSec)
}, "meta.cheatPremiumRemove")
 