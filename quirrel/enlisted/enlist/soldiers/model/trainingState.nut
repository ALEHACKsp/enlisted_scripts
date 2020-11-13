local frp = require("std/frp.nut")
local {userstatTime} = require("enlist/userstat/userstat.nut")
local squadsParams = require("squadsParams.nut")
local { curSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { getGoldToMaxLevel, perkLevelsGrid } = require("perks/perksExp.nut")
local {
  getLinksByType, getObjectsByLink, getLinkedArmyName, getFirstLinkByType,
  getLinkedSquadGuid, getLinkedObjectsValues
} = require("enlisted/enlist/meta/metalink.nut")
local {
  profile, begin_training, cancel_training, end_training, buy_end_training,
  swap_squad_and_reserve_soldiers
} = require("enlisted/enlist/meta/clientApi.nut")
local { trainings } = profile
local msgbox = require("enlist/components/msgbox.nut")
local { collectSoldierData } = require("collectSoldierData.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local {
  allUnlockedSquadsSoldiers, curUnlockedSquadsSoldiers, curArmy, curCampSoldiers,
  curArmies_list, squadsByArmy, curArmyLimits
} = require("state.nut")
local { allReserveSoldiers, curArmyReserve } = require("reserve.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local {
  requiredSoldiers, soldierTiersCount, getTrainingCfgByTier
} = require("config/trainingConfig.nut")
local { perksData, buySoldierMaxLevel } = require("soldierPerks.nut")
local armyEffects = require("armyEffects.nut")
local {
  focusResearch, findResearchTrainClass
} = require("enlisted/enlist/researches/researchesFocus.nut")
local { mkOnlinePersistentWatched } = require("enlist/options/mkOnlinePersistentFlag.nut")

local selectedClass = persist("selectedClass", @() Watched(null))

local maxTrainByClass = ::Computed(@() armyEffects.value?[curArmy.value].class_training ?? {})
local isTrainingRequestInProgress = ::Watched(false)

local allSoldiersClasses = ::Computed(function() {
  local maxTier = soldierTiersCount.value
  local res = {}
  foreach (armyId in curArmies_list.value)
    res[armyId] <- []
      .extend(allUnlockedSquadsSoldiers.value?[armyId] ?? [])
      .extend(allReserveSoldiers.value?[armyId] ?? [])
      .filter(@(soldier) soldier.tier <= maxTier)
      .reduce(function(tbl, soldier) {
          tbl[soldier.sClass] <- true
          return tbl
        }, {})
      .keys()
      .sort(@(a, b) a <=> b)
  return res
})

local curSoldiersClasses = ::Computed(@()
  allSoldiersClasses.value?[curArmy.value] ?? [])

local curSelectedClass = ::Computed(@()
  curSoldiersClasses.value.indexof(selectedClass.value) == null
    ? curSoldiersClasses.value?[0]
    : selectedClass.value)

local setSelectedClass = @(className) selectedClass(className)

local function getTrainingCost(training) {
  local tier = curCampSoldiers.value?[getFirstLinkByType(training, "trainee")].tier
  if (tier == null)
    return 0

  return getTrainingCfgByTier(tier)?.trainingCost ?? 0
}

local armyTrainings = ::Computed(function() {
  local tbl = {}
  trainings.value.each(function(train) {
    local armyId = getLinkedArmyName(train)
    if (armyId != null)
      tbl[armyId] <- train
  })
  return tbl.map(@(training) training.__update({
    cost = getTrainingCost(training)
  }))
})

local curArmyTraining = ::Computed(@() armyTrainings.value?[curArmy.value])

local choosenSoldiers = Watched(array(requiredSoldiers.value))

local hasArmyTraining = ::Computed(@() curArmyTraining.value != null)

local hasSameTier = @(soldier, tier)
  tier == null || soldier.tier == tier

local isInList = @(soldier, list)
  list.findindex(@(s) s?.guid == soldier.guid) != null

local trainingSoldiers = ::Computed(function() {
  local training = curArmyTraining.value
  if (training == null)
    return array(requiredSoldiers.value)

  local sList = []
  foreach (linkType in ["sacrifice", "trainee"])
    sList.extend(getLinksByType(training, linkType))

  sList.sort(@(a, b) a <=> b)
  return sList.map(@(guid) curCampSoldiers.value[guid]).map(collectSoldierData)
})

local trainingSoldiersGuids = ::Computed(function() {
  local sGuids = []
  foreach (training in trainings.value)
    foreach (linkType in ["sacrifice", "trainee"])
      sGuids.extend(getLinksByType(training, linkType))

  local res = {}
  foreach (guid in sGuids)
    res[guid] <- true

  return res
})

local function addSoldierToTrainData(soldierGuid, sTier, sClass, data) {
  if (sTier not in data)
    data[sTier] <- {}
  data[sTier][soldierGuid] <- sClass
}

local fillArmySoldiersTrainData = ::kwarg(
  function(armyId, armySoldiers, perksDataVal, maxTier, isReserve, res) {
    res.current[armyId] <- res.current?[armyId] ?? {}
    res.potential[armyId] <- res.potential?[armyId] ?? {}
    foreach (soldier in armySoldiers) {
      local soldierGuid = soldier.guid
      local perks = perksDataVal?[soldierGuid]
      if (perks == null || perks.level < perks.maxLevel || soldier.tier > maxTier)
        continue

      local sClass = soldier.sClass
      local sTier = soldier.tier
      addSoldierToTrainData(soldierGuid, sTier, sClass, res.potential[armyId])

      if (isReserve)
        addSoldierToTrainData(soldierGuid, sTier, sClass, res.current[armyId])
    }
  }
)

local allTrainData = ::Computed(function() {
  local res = {
    current = {}
    potential = {}
  }
  local maxTier = soldierTiersCount.value
  local perksDataVal = perksData.value
  foreach (armyId, armySoldiers in allReserveSoldiers.value)
    fillArmySoldiersTrainData({ armyId, armySoldiers, perksDataVal, maxTier, res, isReserve = true })
  foreach (armyId, armySoldiers in allUnlockedSquadsSoldiers.value)
    fillArmySoldiersTrainData({ armyId, armySoldiers, perksDataVal, maxTier, res, isReserve = false })
  return res
})

local curTrainingRestSec = ::Computed(function() {
  local endTime = (curArmyTraining.value?.endTime ?? 0).tointeger()
  local curTime = userstatTime.value
  return endTime > 0 && endTime > curTime ? endTime - curTime : 0
})

local canFinishCurTraining = ::Computed(@()
  curArmyTraining.value != null && curTrainingRestSec.value <= 0)

local curArmyTrainingFinishCost = ::Computed(function() {
  local training = curArmyTraining.value
  if (training == null)
    return null
  if (curTrainingRestSec.value <= 0)
    return 0

  local startTime = training?.ctime ?? 0
  local totalTime = (training?.endTime ?? 0) - startTime
  if (totalTime <= 0)
    return 0

  local curTime = ::max(0, userstatTime.value - startTime)
  local cost = training.cost
  return ::clamp(cost - cost * curTime / totalTime, 0, cost)
})

local availArmyClasses = ::Computed(function() {
  local reqSoldiers = requiredSoldiers.value
  return allTrainData.value.current.map(function(tiersList) {
    local res = {}
    foreach (tierList in tiersList.filter(@(tierList) tierList.len() >= reqSoldiers))
      foreach (sGuid, sClass in tierList)
        res[sClass] <- (res?[sClass] ?? 0) + 1
    return res
  })
})

local curArmyAvailClasses = ::Computed(function() {
  local choosen = (choosenSoldiers.value ?? [])
    .reduce(@(res, val) res
      .__update(val != null ? {[val.sClass] = (res?[val.sClass] ?? 0) + 1} : {}), {})
  return (availArmyClasses.value?[curArmy.value] ?? {})
    .map(@(sClassValue, sClass) sClassValue - (choosen?[sClass] ?? 0))
})

local curArmyReservePart = ::Computed(function() {
  local limit = curArmyLimits.value.soldiersReserve
  if (limit <= 0)
    return 0.0
  return curArmyReserve.value.len().tofloat() / limit
})

local hasTrainedSoldier = ::Computed(@()
  hasArmyTraining.value && curTrainingRestSec.value <= 0)

local isAcademyVisible = mkOnlinePersistentWatched("isAcademyVisible", ::Computed(@()
  (allTrainData.value.potential?[curArmy.value] ?? {})
    .findvalue(@(tier) tier.len() >= requiredSoldiers.value) != null
  || curArmyReservePart.value >= 0.5
  || hasTrainedSoldier.value))

local function canBeFreeToTrain(soldier, squadGuid, squadsInfo, choosen) {
  local squadInfo = squadsInfo.findvalue(@(squad) squad.guid == squadGuid)
  if (squadInfo == null)
    return false

  local freeCount = squadInfo.squadSize - squadInfo.size
  if (freeCount <= 0)
    return false

  foreach (choosenSoldier in choosen)
    if (choosenSoldier != null && getLinkedSquadGuid(choosenSoldier) == squadGuid)
      freeCount--

  return freeCount > 0
}

local soldiersList = ::Computed(function() {
  local hasTraining = hasArmyTraining.value
  local armyId = curArmy.value
  local squadsInfo = squadsByArmy.value?[armyId] ?? []
  local potentialTrainData = allTrainData.value.potential?[armyId] ?? {}
  local choosen = hasTraining
    ? trainingSoldiers.value
    : choosenSoldiers.value

  local maxTier = soldierTiersCount.value
  local sClass = curSelectedClass.value
  local sTier = choosen.findvalue(@(s) s != null)?.tier

  return (clone (curArmyReserve.value ?? [])).extend(clone (curUnlockedSquadsSoldiers.value ?? []))
    .filter(@(soldier) soldier.sClass == sClass
      && !isInList(soldier, choosen)
      && soldier.tier <= maxTier)
    .map(function(s) {
      local squadGuid = getLinkedSquadGuid(s)
      local hasMaxLevel = s.guid in potentialTrainData?[s.tier]
      local isReserved = squadGuid == null
      local isTierOk = hasSameTier(s, sTier)
      local canTrain = !hasTraining && isTierOk
      local canBeFree = isReserved
        || canBeFreeToTrain(s, squadGuid, squadsInfo, choosen)
      return s.__merge({
        canTrain = canTrain
        isTrainAvailable = !hasTraining && hasMaxLevel && (isReserved || canBeFree)
        hasMaxLevel = hasMaxLevel
        canSelect = canTrain && hasMaxLevel && (isReserved || canBeFree)
        hasAlertStyle = !hasMaxLevel || hasTraining || !isTierOk
        errorLocId = hasTraining ? "retraining/hasTraining"
          : !isTierOk ? "retraining/wrongSoldierTier"
          : !hasMaxLevel ? "retraining/maxLevelNotReached"
          : !isReserved ? "retraining/cantTrainActiveSoldiers"
          : ""
      })
    })
    .sort(@(a, b) b.isTrainAvailable <=> a.isTrainAvailable
      || a.tier <=> b.tier || b.guid <=> a.guid)
})

local function clearChoosenSoldiers() {
  choosenSoldiers(array(requiredSoldiers.value))
}

frp.subscribe([curArmy, curSection], function(_) {
  if (curArmyTraining.value == null)
    clearChoosenSoldiers()
})

local function showTrainResearchMsg(soldier) {
  local { sClass, tier } = soldier
  if ((maxTrainByClass.value?[sClass] ?? 0) >= tier)
    return false

  local research = findResearchTrainClass(soldier)
  if (research == null)
    msgbox.show({ text = ::loc("msg/cantTrainClassHigher") })
  else
    msgbox.show({
      text = ::loc("msg/needResearchToTrainHigher")
      buttons = [
        { text = ::loc("OK"), isCurrent = true }
        { text = ::loc("GoToResearch"), action = @() focusResearch(research) }
      ]
    })
  return true
}

local function buyMaxSoldierLevelMsg(perks, cb) {
  local maxLevelCost = getGoldToMaxLevel({
    level = perks.level
    maxLevel = perks.maxLevel
    exp = perks.exp
    lvlsCfg = perkLevelsGrid.value
  })
  if (maxLevelCost <= 0)
    return null

  purchaseMsgBox({
    price = maxLevelCost
    currencyId = "EnlistedGold"
    title = ::loc("soldierMaxLevel")
    description = ::loc("buy/soldierMaxLevelConfirm")
    purchase = function() {
      isTrainingRequestInProgress(true)
      buySoldierMaxLevel(perks.guid, maxLevelCost, function(res) {
        isTrainingRequestInProgress(false)
        cb()
      })
    }
    srcComponent = "buy_soldier_level"
  })
}

local function addSoldierImpl(soldier) {
  local idx = choosenSoldiers.value.findindex(@(s) s == null)
  if (idx != null) {
    choosenSoldiers(function(s) { s[idx] = soldier })
    ::gui_scene.setTimeout(0.1, @() ::anim_start(soldier.guid))
  }
}

local function addSoldier(soldier) {
  if (soldier.canSelect) {
    addSoldierImpl(soldier)
    return
  }

  if (soldier.canTrain) {
    local curArmyId = curArmy.value
    local soldierClass = soldier.sClass
    local squadGuid = getLinkedSquadGuid(soldier)
    local squadId = (squadsByArmy.value?[curArmyId] ?? [])
      .findvalue(@(s) s.guid == squadGuid)?.squadId
    local squadSoldiers = getLinkedObjectsValues(curCampSoldiers.value, squadGuid)
    local availableClasses = clone (squadsParams.value?[curArmyId][squadId]?.maxClasses ?? {})
    foreach (squadSoldier in squadSoldiers)
      if (squadSoldier.sClass in availableClasses)
        availableClasses[squadSoldier.sClass]--

    local choosen = choosenSoldiers.value
    local availableReserve = curArmyReserve.value
      .filter(function(reserveSoldier) {
        if (choosen.findvalue(@(choosenSoldier) choosenSoldier?.guid == reserveSoldier.guid) != null)
          return false

        local sClass = reserveSoldier.sClass
        return sClass == soldierClass || (availableClasses?[sClass] ?? 0) > 0
      })
      .sort(@(a, b) (b.sClass == soldierClass) <=> (a.sClass == soldierClass)
        || b.tier <=> a.tier)

    if (availableReserve.len() > 0)
      return msgbox.show({
        text = ::loc("retraining/replaceSquadSoldierToTrain")
        buttons = [
          { text = ::loc("Ok"), isCancel = true, isCurrent = true }
          {
            text = ::loc("btn/replaceSquadSoldierToTrain"),
            action = function() {
              isTrainingRequestInProgress(true)
              swap_squad_and_reserve_soldiers(curArmyId, soldier.guid, availableReserve[0].guid, function(res) {
                isTrainingRequestInProgress(false)
                soldier = soldiersList.value.findvalue(@(s) s.guid == soldier.guid)
                if (soldier != null)
                  addSoldierImpl(collectSoldierData(soldier))
              })
            }
          }
        ]
      })
  }

  return msgbox.show({ text = ::loc(soldier.errorLocId) })
}

local function checkMaxLevelToAddSoldier(soldier) {
  if (isTrainingRequestInProgress.value)
    return

  if (showTrainResearchMsg(soldier))
    return

  if (soldier.canTrain && !soldier.hasMaxLevel) {
    local perks = perksData.value?[soldier.guid]
    if (perks == null)
      return

    local msgboxButtons = [{ text = ::loc("Ok"), isCancel = true, isCurrent = true }]
    if (monetization.value)
      msgboxButtons.append({
        text = ::loc("btn/buyMaxSoldierLevel"),
        action = function() {
          buyMaxSoldierLevelMsg(perks, function() {
            soldier = soldiersList.value.findvalue(@(s) s.guid == soldier.guid)
            if (soldier != null)
              addSoldier(collectSoldierData(soldier))
          })
        }
      })
    return msgbox.show({
      text = ::loc(soldier.errorLocId)
      buttons = msgboxButtons
    })
  }

  addSoldier(soldier)
}

local function removeSoldier(soldier) {
  local idx = choosenSoldiers.value.findindex(@(s) s != null && s.guid == soldier.guid)
  if (idx != null)
    choosenSoldiers(function(s) { s[idx] = null })
}

local function beginTraining(soldierGuids, cb = null) {
  if (isTrainingRequestInProgress.value)
    return
  isTrainingRequestInProgress(true)
  local cb2 = function(res) {
    isTrainingRequestInProgress(false)
    debugTableData(res)
    if (cb)
      cb(res)
  }
  begin_training(soldierGuids, cb2)
}

local function cancelTraining(training) {
  if (isTrainingRequestInProgress.value)
    return
  isTrainingRequestInProgress(true)
  cancel_training(training.guid, function(res) {
    isTrainingRequestInProgress(false)
    clearChoosenSoldiers()
  })
}

local function endTraining(training, cb = null) {
  if (isTrainingRequestInProgress.value)
    return
  isTrainingRequestInProgress(true)
  end_training(training.guid, function(res) {
    isTrainingRequestInProgress(false)
    cb?(res)
  })
}

local function buyEndTraining(training, cost, cb = null) {
  if (isTrainingRequestInProgress.value)
    return
  isTrainingRequestInProgress(true)
  buy_end_training(training.guid, cost, function(res) {
    isTrainingRequestInProgress(false)
    cb?(res)
  })
}

local getTrainingForCurrentArmy = @()
  getObjectsByLink(trainings.value, curArmy.value, "army")?[0]

local function cancelTrainingForCurrentArmy() {
  local training = getTrainingForCurrentArmy()
  if (training)
    cancelTraining(training)
}

local function cancelTrainingByGuid(trainingGuid) {
  local training = trainings.value?[trainingGuid]
  if (training)
    cancelTraining(training)
}

local function endTrainingByGuid(trainingGuid) {
  local training = trainings.value?[trainingGuid]
  if (training)
    endTraining(training)
}

local function endTrainingForCurrentArmy() {
  local training = getTrainingForCurrentArmy()
  if (training)
    endTraining(training)
}

console.register_command(@() print(getTrainingForCurrentArmy()?.guid ?? "(none)"), "meta.getTraining")
console.register_command(@() cancelTrainingForCurrentArmy(), "meta.cancelTraining")
console.register_command(@() endTrainingForCurrentArmy(), "meta.endTraining")

return {
  availArmyClasses
  curArmyAvailClasses
  isAcademyVisible
  curTrainingRestSec
  canFinishCurTraining
  curArmyTrainingFinishCost
  hasTrainedSoldier
  allSoldiersClasses
  curSoldiersClasses
  curSelectedClass
  setSelectedClass
  trainingSoldiers
  trainingSoldiersGuids
  choosenSoldiers
  clearChoosenSoldiers
  soldiersList
  checkMaxLevelToAddSoldier
  removeSoldier
  armyTrainings
  hasArmyTraining
  curArmyTraining
  maxTrainByClass
  soldierTiersCount
  getTrainingCfgByTier
  isTrainingRequestInProgress

  beginTraining
  cancelTrainingByGuid
  cancelTrainingForCurrentArmy
  endTrainingByGuid
  endTraining
  buyEndTraining
  endTrainingForCurrentArmy
  getTrainingForCurrentArmy
}
 