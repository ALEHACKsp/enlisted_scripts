local { logerr } = require("dagor.debug")
local { lerp } = require("std/math.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local client = require("enlisted/enlist/meta/clientApi.nut")
local { receivedUnlocks } = require("enlisted/enlist/meta/profile.nut")
local {
  armies, curCampSquads, curArmy, curArmyData, curUnlockedSquads
} = require("state.nut")
local {
  armyLevelsData, armiesUnlocks
} = require("enlisted/enlist/campaigns/armiesConfig.nut")

local forceScrollToLevel = Watched(null)
local curUnlockedSquadId = Watched(null)
local isBuyLevelInProgress = ::Watched(false)

local curUnlockedSquadsIds = ::Computed(@()
  curUnlockedSquads.value.reduce(@(res, s) res.__update({ [s.squadId] = true }), {}))

local curArmyLevels = ::Computed(function() {
  local expTo = 0
  local posTo = 0.0
  return armyLevelsData.value
    .map(function(levelData, idx) {
      local exp = levelData.exp
      local expFrom = expTo
      expTo += exp
      local posFrom = posTo
      if (exp > 0)
        posTo += 1.0
      return {
        level = idx
        posFrom = max(posFrom - 0.5, 0.0)
        posTo = max(posTo - 0.5, 0.0)
        expFrom = expFrom
        expTo = expTo
        expSize = exp
        levelCost = levelData.levelCost
      }
    })
})

local curArmyLevelsSize = ::Computed(@()
  curArmyLevels.value.len() ? curArmyLevels.value.top().posTo + 0.5 : 0.0)

local function getPositionByExp(exp) {
  if (exp <= 0)
    return 0.0

  local index = curArmyLevels.value.findindex(@(val) val.expFrom <= exp && exp < val.expTo)
  if (index == null)
    return curArmyLevelsSize.value

  local interval = curArmyLevels.value[index]
  local posTo = index < curArmyLevels.value.len() - 1 ? interval.posTo : curArmyLevelsSize.value
  return lerp(interval.expFrom, interval.expTo, interval.posFrom, posTo, exp)
}

local function getLevelDataByExp(exp, expGrid) {
  local res = {
    level = 1
    expToLevelRest = 0
    expToLevelTotal = 0
    exp = 0
  }
  local expTotal = 0
  foreach (lvl, levelData in expGrid) {
    expTotal += levelData.exp
    if (exp < expTotal) {
      res.expToLevelRest = expTotal - exp
      res.expToLevelTotal = levelData.exp
      res.exp = levelData.exp - expTotal + exp
      break
    }
    res.level = ::max(res.level, lvl + 1)
  }
  return res
}

local curArmyExp = ::Computed(@() curArmyData.value?.exp ?? 0)
local curArmyLevel = ::Computed(@() curArmyData.value?.level ?? 0)
local curBuyLevelData = ::Computed(function() {
  local levelData = armyLevelsData.value?[curArmyLevel.value]
  local levelExp = levelData?.exp ?? 0
  local levelCost = levelData?.levelCost ?? 0
  if (levelExp <= 0 || levelCost <= 0)
    return null

  local needExp = levelExp - curArmyExp.value
  if (needExp <= 0)
    return null

  return {
    needExp = needExp
    cost = ::max(levelCost * needExp / levelExp, 1)
  }
})

local curArmyUnlocks = ::Computed(@() armiesUnlocks.value
  .filter(@(u) u.armyId == curArmy.value)
  .sort(@(a, b) a.level <=> b.level || a.exp <=> b.exp))

local hasArmyUnlocks = ::Computed(@() curArmyUnlocks.value.len() > 0)

local curArmySquadsUnlocks = ::Computed(@() curArmyUnlocks.value
  .filter(@(u) u.unlockType == "squad"))

local curArmyLevelRewardsUnlocks = ::Computed(@() curArmyUnlocks.value
  .filter(@(u) u.unlockType == "level_reward"))

local getSquadByUnlock = @(allSquads, unlock) allSquads
  .findvalue(@(squad) squad.squadId == unlock.unlockId &&
    (getLinkedArmyName(squad) ?? "") == unlock.armyId)

local curArmyNextUnlockLevel = ::Computed(function() {
  local allSquads = curCampSquads.value
  local uReceived = receivedUnlocks.value
  local squadUnlocks = curArmySquadsUnlocks.value
  local rewardUnlocks = curArmyLevelRewardsUnlocks.value
  local maxLevel = ::max(squadUnlocks.reduce(@(res, val) ::max(val.level, res), 0),
                         rewardUnlocks.reduce(@(res, val) ::max(val.level, res), 0))

  local nextLevel = 0
  for (local lvl = 1; lvl <= maxLevel; lvl++) {
    nextLevel = lvl
    local unlock = squadUnlocks.findvalue(@(u) u.level == lvl)
      ?? rewardUnlocks.findvalue(@(u) u.level == lvl)
    if (unlock != null)
      if ((unlock.unlockType == "squad" && (getSquadByUnlock(allSquads, unlock)?.locked ?? false))
        || (unlock.unlockType == "level_reward" && !(unlock.unlockGuid in uReceived)))
        break
  }
  return nextLevel
})

local curArmyRewardsUnlocks = ::Computed(@()
  curArmyUnlocks.value.filter(@(u) u.unlockType != "squad" && u.unlockType != "level_reward")
    .map(@(u) u.__update({
      isMultiple = (u?.multipleUnlock.periods ?? 0) > 0
        && (u.multipleUnlock.expEnd ?? 0) > (u.multipleUnlock.expBegin ?? 0)
    })))

local function getUnlockProgress(armyExp, unlockExp, expGrid) {
  local progress = 0
  if (armyExp >= unlockExp)
    progress = 100
  else {
    local lvlData = getLevelDataByExp(armyExp, expGrid)
    local cutExp = armyExp - lvlData.exp
    progress = 100 * lvlData.exp / (unlockExp - cutExp)
  }
  return {
    progress = ::min(progress, 100)
    isReached = armyExp >= unlockExp
  }
}

local researchSquads = ::Computed(function() {
  local allSquads = curCampSquads.value
  local lockedSquads = {}
  foreach (squad in allSquads) {
    local armyId = getLinkedArmyName(squad) ?? ""
    if (squad.locked)
      lockedSquads[armyId] <- (lockedSquads?[armyId] ?? {})
        .__update({ [squad.squadId] = squad.guid })
  }

  local expGrid = armyLevelsData.value
  local res = {}
  foreach (army in armies.value) {
    local armyId = army.guid
    local lockedByArmy = lockedSquads?[armyId] ?? {}
    local armyResearchSquads = curArmySquadsUnlocks.value
      .filter(@(u) u.unlockId in lockedByArmy)

    if (armyResearchSquads.len() > 0) {
      local u = armyResearchSquads[0]
      local squadGuid = lockedByArmy?[u.unlockId]
      local squad = allSquads?[squadGuid]
      if (squad != null)
        res[armyId] <- squad
          .__merge(getUnlockProgress(army.exp, u.exp, expGrid))
    }
  }

  return res
})

local hasCurArmyUnlockAlert = ::Computed(@()
  curArmySquadsUnlocks.value.findvalue(@(u) curArmyLevel.value >= u.level
    && curArmyExp.value >= u.exp
    && !(u.unlockId in curUnlockedSquadsIds.value)) != null)

local function unlockSquad(squadId) {
  if (squadId in curUnlockedSquadsIds.value) {
    logerr($"Squad {squadId} has already unlocked.")
    return
  }

  client.unlock_squad(curArmy.value, squadId, function(res) {
    local unlockedSquadId = res?.squads.values()[0].squadId
    if (unlockedSquadId != null)
      curUnlockedSquadId(unlockedSquadId)
  })
}

local function buyArmyLevel() {
  if (isBuyLevelInProgress.value)
    return
  local { needExp = 0, cost = 0 } = curBuyLevelData.value
  if (needExp <=0 || cost <= 0)
    return

  isBuyLevelInProgress(true)
  client.buy_army_exp(curArmy.value, needExp, cost, @(res) isBuyLevelInProgress(false))
}

local viewSquadId = persist("viewSquadId", @() Watched(null))

return {
  curArmyLevels = curArmyLevels
  curArmyLevelsSize = curArmyLevelsSize
  getPositionByExp = getPositionByExp
  curArmyExp = curArmyExp
  curArmyLevel = curArmyLevel
  curBuyLevelData = curBuyLevelData
  unlockSquad = unlockSquad
  hasArmyUnlocks = hasArmyUnlocks
  buyArmyLevel = buyArmyLevel
  curArmySquadsUnlocks = curArmySquadsUnlocks
  curArmyRewardsUnlocks = curArmyRewardsUnlocks
  curArmyLevelRewardsUnlocks = curArmyLevelRewardsUnlocks
  curArmyNextUnlockLevel = curArmyNextUnlockLevel
  curUnlockedSquadId = curUnlockedSquadId
  researchSquads = researchSquads
  hasCurArmyUnlockAlert = hasCurArmyUnlockAlert
  viewSquadId = viewSquadId
  receivedUnlocks = receivedUnlocks
  forceScrollToLevel = forceScrollToLevel
}

 