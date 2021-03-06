local {configs} = require("enlisted/enlist/configs/configs.nut")

local perkLevelsGrid = ::Computed(@() configs.value?.perk_levels_grid)

local getExpToNextLevel = @(level, maxLevel, lvlsCfg) lvlsCfg == null ? 0
  : level < (maxLevel ?? lvlsCfg.MAX_LEVEL) ? (lvlsCfg.expToLevel?[level] ?? lvlsCfg.expToPerkOnMaxLevel)
  : lvlsCfg.expToPerkOnMaxLevel

local getGoldToNextLevel = @(level, maxLevel, lvlsCfg) lvlsCfg == null ? 0
  : level < (maxLevel ?? lvlsCfg.MAX_LEVEL) ? (lvlsCfg.goldToLevel?[level] ?? lvlsCfg.goldToPerkOnMaxLevel)
  : lvlsCfg.goldToPerkOnMaxLevel

local getNextLevelData = ::kwarg(function(level, maxLevel, exp, lvlsCfg) {
  local expToLevel = getExpToNextLevel(level, maxLevel, lvlsCfg)
  local goldToLevel = getGoldToNextLevel(level, maxLevel, lvlsCfg)
  if (expToLevel <= 0 || goldToLevel <= 0)
    return null

  local needExp = expToLevel - exp
  return {
    exp = needExp
    cost = ::max(goldToLevel * needExp / expToLevel, 1)
  }
})

local getGoldToMaxLevel = ::kwarg(function(level, maxLevel, exp, lvlsCfg) {
  local totalPrice = 0
  for (local lvl = level; lvl < maxLevel; lvl++)
    totalPrice += getNextLevelData({
      level = lvl
      maxLevel = maxLevel
      exp = lvl == level ? exp : 0
      lvlsCfg = lvlsCfg
    })?.cost ?? 0

  return totalPrice
})

return {
  perkLevelsGrid = perkLevelsGrid
  getExpToNextLevel = getExpToNextLevel
  getGoldToNextLevel = getGoldToNextLevel
  getNextLevelData = getNextLevelData
  getGoldToMaxLevel = getGoldToMaxLevel
}
 