local u = require("std/underscore.nut")
local frp = require("std/frp.nut")
local { logerr } = require("dagor.debug")
local { curArmies_list, getSoldiersByArmy, curCampSquads, chosenSquadsByArmy, curCampaign
} = require("state.nut")
local { getLinkedSquadGuid } = require("enlisted/enlist/meta/metalink.nut")
local {
  getExpToNextLevel, perkLevelsGrid, getNextLevelData
} = require("perks/perksExp.nut")
local style = require("enlisted/enlist/viewConst.nut")
local colorize = require("enlist/colorize.nut")
local perksList = require("enlisted/enlist/soldiers/model/perks/perksList.nut")
local perksStats = require("enlisted/enlist/soldiers/model/perks/perksStats.nut")
local {
  profile, get_perks_choice, choose_perk, change_perk_choice, buy_soldier_exp,
  buy_soldier_max_level
} = require("enlisted/enlist/meta/clientApi.nut")
local perksData = profile.soldierPerks
local popupsState = require("enlist/popup/popupsState.nut")
local { gameProfile } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")

local perkActionsInProgress = ::Watched({})
local perkChoiceWndParams = persist("perkChoiceWndParams", @() ::Watched(null))

local getNoAvailPerksText = @(soldier)
  soldier?.canChangePerk
    ? ::loc("perk/need_retraining_points")
    : ::loc("get_more_exp_to_add_perk", {
        value = colorize(style.titleTxtColor,
          getExpToNextLevel(soldier.level, soldier.maxLevel,
            perkLevelsGrid.value) - soldier.exp)
      })


local function obtainPerksChoice(soldierGuid, tierIdx, slotIdx, cb) {
  if (soldierGuid in perkActionsInProgress.value)
    return

  local callCb = function(res) {
    if (cb)
      cb(res)
  }

  local soldierPerks = perksData.value?[soldierGuid]
  if ((soldierPerks?.availPerks ?? 0) <= 0 && (soldierPerks?.prevTier ?? -1) < 0)
    return callCb({ errorText = getNoAvailPerksText(soldierPerks) })

  local tierData = perksData.value?[soldierGuid].tiers[tierIdx]
  if ((tierData?.choiceAmount ?? 0) <= 0)
    return callCb({ errorText = ::loc("perk/no_perks_to_select") })

  perkActionsInProgress[soldierGuid] <- true
  local handleResult = function(res) {
    delete perkActionsInProgress[soldierGuid]
    if ((res?.error ?? "") != "") {
      cb({ errorText = ::loc(res.error) })
      return
    }

    cb(res?.choiceData ?? {})
  }

  get_perks_choice(soldierGuid, tierIdx, slotIdx, handleResult)
}


local resData = @(errorText) { isSuccess = !errorText, errorText = errorText }

local function getTierAvailableData(soldier, tierData) {
  foreach(tData in soldier?.tiers ?? [])
    if (tData == tierData)
      return resData(null)
    else if (tData.slots.indexof(null) != null)
      return resData(::loc("special_perks_unlock_condition",
        { value = colorize(style.titleTxtColor, tData.slots.len()) }))
  return resData(::loc("perks_not_available"))
}

local function choosePerk(soldierGuid, tierIdx, slotIdx, perkId, cb = @(res) null) {
  if (soldierGuid in perkActionsInProgress.value)
    return cb(resData(null))

  local soldier = perksData.value[soldierGuid]
  local tierData = soldier.tiers[tierIdx]
  local slots = tierData.slots
  if (!soldier?.canChangePerk && (slots[slotIdx] ?? "") != "")
    return cb(resData(::loc("Earn soldier max level to change perks")))

  if (!(slotIdx in slots))
    return cb(resData(::loc("Not exist slot index")))

  local processChoiceData = function(choiceData) {
    if (choiceData?.errorText)
      return cb(resData(choiceData?.errorText))

    if (choiceData.soldierGuid != soldierGuid ||
        choiceData.tierIdx != tierIdx ||
        choiceData.slotIdx != slotIdx)
      return cb(resData(::loc("Perk choice data mismatch")))

    local choice = choiceData.choice
    if (choice.indexof(perkId) == null && slots[slotIdx] != perkId)
      return cb(resData(::loc("Perk not available")))

    perkActionsInProgress[soldierGuid] <- true
    choose_perk(soldierGuid, tierIdx, slotIdx, perkId,
      function(res) {
        delete perkActionsInProgress[soldierGuid]
        cb(resData(res?.error))
      })
  }

  obtainPerksChoice(soldierGuid, tierIdx, slotIdx, processChoiceData)
}

local changePerkCost = ::Computed(@() gameProfile.value?.perkChoiceChangeCost ?? 0)
local function changePerks(soldierGuid, tierIdx, slotIdx, cb) {
  if (soldierGuid in perkActionsInProgress.value)
    return
  local cost = changePerkCost.value
  if (cost <= 0) {
    logerr($"Try to change perk when invalid cost {cost}")
    return
  }
  perkActionsInProgress[soldierGuid] <- true
  change_perk_choice(soldierGuid, tierIdx, slotIdx, cost,
    function(res) {
      delete perkActionsInProgress[soldierGuid]
      cb((res?.error ?? "") != "" ? { errorText = ::loc(res.error) } : res?.choiceData)
    })
}


local getRetrainingPointsText = @(soldier)
  !soldier?.canChangePerk ? ""
    : soldier.availPerks ? ::loc("use_perk_rp_info")
    : ::loc("get_perk_rp_info", {
        value = getExpToNextLevel(soldier.level, soldier.maxLevel,
          perkLevelsGrid.value) - soldier.exp
      })

local function getTotalPerkValue(perks, perkName) {
  local sum = 0.0
  foreach (tier in perks?.tiers ?? [])
    foreach (perkId in tier?.slots ?? [])
      if (tier?.perks?.indexof?(perkId) != null) {
        local stats = perksList?[perkId]?.stats ?? {}
        sum += stats?[perkName]
          ? stats[perkName] * perksStats.stats[perkName].base_power
          : 0.0
      }
  return sum
}

local function getPerksCount(perks) {
  local count = 0
  foreach (tier in perks?.tiers ?? [])
    foreach (perkId in tier?.slots ?? [])
      count += (perkId ?? "") == "" ? 0 : 1
  return count
}

local notChoosenPerkSoldiers = Watched({})
local notChoosenPerkSquads = Watched({})
local notChoosenPerkArmies = Watched({})

local function updateNotChosenPerks() {
  local soldiersList = {}
  local squadsList = {}
  local armiesList = {}

  foreach (armyId in curArmies_list.value) {
    armiesList[armyId] <- 0
    squadsList[armyId] <- {}
    local chosenSquads = chosenSquadsByArmy.value?[armyId]
    if (chosenSquads == null)
      continue

    foreach (soldier in getSoldiersByArmy(armyId)) {
      local guid = soldier.guid
      local perks = perksData.value?[guid]
      if (perks?.canChangePerk)
        continue

      local availPerks = (perks?.availPerks ?? 0)
      if ((perks?.prevTier ?? -1) >= 0)
        availPerks++
      if (availPerks == 0)
        continue
      soldiersList[guid] <- availPerks

      local squadId = curCampSquads.value?[getLinkedSquadGuid(soldier)].squadId
      if (squadId == null)
        continue
      squadsList[armyId][squadId] <- (squadsList[armyId]?[squadId] ?? 0) + 1

      if (chosenSquads.findindex(@(s) s?.squadId == squadId) != null)
        armiesList[armyId]++
    }
  }

  if (!u.isEqual(armiesList, notChoosenPerkArmies.value))
    notChoosenPerkArmies(armiesList)
  if (!u.isEqual(soldiersList, notChoosenPerkSoldiers.value))
    notChoosenPerkSoldiers(soldiersList)
  if (!u.isEqual(squadsList, notChoosenPerkSquads.value))
    notChoosenPerkSquads(squadsList)
}
updateNotChosenPerks()

//no need to subscribe on armies, soldier can not change army
frp.subscribe([perksData, curCampaign, chosenSquadsByArmy]
  @(_) updateNotChosenPerks())

local function getPerkPointsInfo(sPerksData, exclude = {}) {
  local res = {
    used = {}
    total = clone (sPerksData?.points ?? {})
    bonus = {}
  }

  foreach (pTier in sPerksData.tiers)
    foreach (pSlot in pTier.slots)
      if (pSlot != null && !exclude?[pSlot]) {
        local perkCfg = perksList?[pSlot] ?? {}
        foreach (pPointId, pPointCost in perkCfg?.cost ?? {})
          res.used[pPointId] <- (res.used?[pPointId] ?? 0) + pPointCost
        foreach (pPointId, pPointBonus in perkCfg?.bonus ?? {}) {
          res.bonus[pPointId] <- (res.bonus?[pPointId] ?? 0) + pPointBonus
          res.total[pPointId] <- (res.total?[pPointId] ?? 0) + pPointBonus
        }
      }

  return res
}

local function buySoldierLevel(perks, cb) {
  local nextLevelData = getNextLevelData({
    level = perks.level
    maxLevel = perks.maxLevel
    exp = perks.exp
    lvlsCfg = perkLevelsGrid.value
  })
  if (nextLevelData == null)
    return

  buy_soldier_exp(perks.guid, nextLevelData.exp, nextLevelData.cost, cb)
}


local function buySoldierMaxLevel(guid, cost, cb = @(res) null) {
  buy_soldier_max_level(guid, cost, cb)
}

local showActionError = @(text)
  popupsState.addPopup({ id = "perk_assign_msg", text = text, styleName = "error" })

local function showPerksChoice(soldierGuid, tierIdx, slotIdx) {
  obtainPerksChoice(soldierGuid, tierIdx, slotIdx,
    @(choiceData) "errorText" in choiceData ? showActionError(choiceData.errorText)
      : perkChoiceWndParams(choiceData))
}

return {
  perksData = perksData
  notChoosenPerkArmies = notChoosenPerkArmies
  notChoosenPerkSquads = notChoosenPerkSquads
  notChoosenPerkSoldiers = notChoosenPerkSoldiers
  perkActionsInProgress = perkActionsInProgress
  perkChoiceWndParams = perkChoiceWndParams
  changePerkCost = changePerkCost

  obtainPerksChoice = obtainPerksChoice
  choosePerk = choosePerk
  changePerks = changePerks
  getTierAvailableData = getTierAvailableData
  getNoAvailPerksText = getNoAvailPerksText
  getRetrainingPointsText = getRetrainingPointsText
  getTotalPerkValue = getTotalPerkValue
  getPerksCount = getPerksCount

  getPerkPointsInfo = getPerkPointsInfo
  buySoldierLevel = buySoldierLevel
  buySoldierMaxLevel = buySoldierMaxLevel
  showActionError = showActionError
  showPerksChoice = showPerksChoice
}
 