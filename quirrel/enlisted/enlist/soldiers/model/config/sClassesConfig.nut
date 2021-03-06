require("enlisted/enlist/soldiers/model/onlyInEnlistVm.nut")("squadsConfig")

local serverConfigs = require("enlisted/enlist/configs/configs.nut").configs

local sClassesCfg = ::Computed(function() {
  local baseClasses = serverConfigs.value?.soldier_classes ?? {}
  local tiers = (serverConfigs.value?.perkPointsTiers ?? {})
  return baseClasses.map(@(c) c.__merge({ pointsByTiers = tiers?[c?.pointsGenId] ?? [] }))
})

return sClassesCfg 