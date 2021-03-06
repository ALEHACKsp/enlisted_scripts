local { configs } = require("enlisted/enlist/configs/configs.nut")

const TRAINING_SOLDIERS_REQ = 3

local trainingConfig = ::Computed(@() configs.value?.training_config ?? {})

local requiredSoldiers = ::Computed(@()
  trainingConfig.value?.requiredSoldiers ?? TRAINING_SOLDIERS_REQ)

local soldierTiersCount = ::Computed(@() (trainingConfig.value?.trainingTiers ?? []).len())

local getTrainingCfgByTier = @(tier) trainingConfig.value?.trainingTiers[tier - 1]

return {
  requiredSoldiers
  soldierTiersCount
  getTrainingCfgByTier
} 