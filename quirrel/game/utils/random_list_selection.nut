local random = require("dagor.random")

local function selectRandom(list) {
  local totalWeight = 0.0
  foreach (groupName, weight in list)
    totalWeight += weight
  if (totalWeight == 0.0)
    return null
  local randPt = random.rnd_float(0, totalWeight)
  local curWeight = 0.0
  foreach (groupName, weight in list) {
    curWeight += weight
    if (randPt < curWeight) {
      return groupName
    }
  }
  return null
}

return selectRandom
 