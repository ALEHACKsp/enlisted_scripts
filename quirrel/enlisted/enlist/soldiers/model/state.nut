require("onlyInEnlistVm.nut")("soldiersState")

local { rand } = require("math")
local { endswith } = require("string")
local {
  gameProfile, availableCampaigns, allArmiesInfo
} = require("config/gameProfile.nut")
local { curCampaign, setCurCampaign } = require("enlisted/enlist/meta/curCampaign.nut")
local { hasPremium } = require("enlisted/enlist/currency/premium.nut")
local { curBonusesEffects } = require("enlisted/enlist/currency/bonuses.nut")
local { squadsCfgById } = require("config/squadsConfig.nut")
local frp = require("std/frp.nut")
local openCrate = require("openCrate.nut")
local armyEffects = require("armyEffects.nut")
local {
  set_squad_order, add_army_exp, reset_profile, update_profile, set_vehicle_to_squad,
  soldiers_regenerate_view, add_items_by_type
} = require("enlisted/enlist/meta/clientApi.nut")
local {
  armies, squads, soldiersLook, cratesContent, curArmiesList, itemsByArmies,
  curCampItems, soldiersByArmies, curCampSoldiers, squadsByArmies, curCampSquads
} = require("enlisted/enlist/meta/profile.nut")
local {
  getObjectsByLinkSorted, getObjectsByLink, getObjectsTableByLinkType,
  getLinkedSquadGuid, getLinkedObjects, getItemIndex
} = require("enlisted/enlist/meta/metalink.nut")
local squadsParams = require("squadsParams.nut")
local mkOnlineSaveData = require("enlist/options/mkOnlineSaveData.nut")
local changeOrderQueue = require("changeOrderQueue.nut")
local armiesPresentation = require("enlisted/globals/armiesPresentation.nut")
local squadsPresentation = require("enlisted/globals/squadsPresentation.nut")


local curArmiesStorage = mkOnlineSaveData("curArmies", @() {})
local setCurArmies = curArmiesStorage.setValue
local curArmies = curArmiesStorage.watch
local playerSelectedSquadsStorage = mkOnlineSaveData("playerSelectedSquads", @() {})
local setPlayerSelectedSquads = playerSelectedSquadsStorage.setValue
local playerSelectedSquads = playerSelectedSquadsStorage.watch


local allAvailableArmies = ::Computed(function() {
  local res = {}
  foreach (campaign in availableCampaigns.value)
    res[campaign] <- (gameProfile.value?.campaigns[campaign].armies ?? []).map(@(a) a.id)
  return res
})

local playerSelectedArmy = Watched(null)
local isArmyCalculatedChange = false
local function recalcArmy() {
  local armyId = curArmies.value?[curCampaign.value]
  if (armyId != null && curArmiesList.value.indexof(armyId) == null)
    armyId = curArmiesList.value?[0]
  isArmyCalculatedChange = true
  playerSelectedArmy(armyId)
  isArmyCalculatedChange = false
}
recalcArmy()
frp.subscribe([curArmies, curCampaign, curArmiesList], @(_) recalcArmy())

local curArmy = ::Computed(@() playerSelectedArmy.value)

local curArmyData = ::Computed(@() armies.value?[curArmy.value])

local mteam = ::Computed(@() endswith(curArmy.value ?? "", "axis") ? 1 : 0)

playerSelectedArmy.subscribe(function(army){
  if (isArmyCalculatedChange)
    return
  local campaign = curCampaign.value
  if (curArmies.value?[campaign] != army)
    setCurArmies(curArmies.value.__merge({ [campaign] = army }))
})

local armyLimitsDefault = {
  maxSquadsInBattle = 1
  maxInfantrySquads = 1
  maxVehicleSquads = 0
  soldiersReserve = 0
}

local limitsByArmy = ::Computed(function() {
  local res = {}
  local armiesInfo = allArmiesInfo.value
  local premiumBonuses = gameProfile.value?.premiumBonuses
  local boughtEffects = curBonusesEffects.value
  local effects = armyEffects.value

  foreach (armyId in curArmiesList.value)
    res[armyId] <- armyLimitsDefault.map(function(val, key) {
      local keyValue = (armiesInfo?[armyId][key] ?? val)
        + (boughtEffects?[key] ?? 0)
        + (effects?[armyId][key] ?? 0)

      if (hasPremium.value)
        keyValue += premiumBonuses?[key] ?? 0
      return keyValue
    })

  return res
})

local curArmyLimits = ::Computed(@()
  limitsByArmy.value?[curArmy.value] ?? armyLimitsDefault)

local sortByIndex = @(a,b) getItemIndex(a) <=> getItemIndex(b)
local objInfoByGuid = ::Computed(@() curCampSoldiers.value.__merge(curCampItems.value))

local soldiersBySquad = ::Computed(@()
  getObjectsTableByLinkType(curCampSoldiers.value, "squad")
    .map(@(list) list.sort(sortByIndex)))

local getItemOwnerGuid = @(itemGuid) (curCampItems.value?[itemGuid].links ?? {})
  .keys()
  .findvalue(@(guid) guid in curCampSoldiers.value || guid in curCampItems.value)

local function getItemOwnerSoldier(itemGuid) {
  foreach(guid, linkType in curCampItems.value?[itemGuid].links ?? {})
    if (guid in curCampSoldiers.value)
      return curCampSoldiers.value[guid]
  return null
}

local vehicleBySquad = ::Computed(@()
  getObjectsTableByLinkType(curCampItems.value, "curVehicle")
    .map(@(list) list[0]))

local getSquadConfig = @(squadId, armyId = null)
  squadsCfgById.value?[armyId ?? curArmy.value][squadId]

local squadsByArmy = ::Computed(function() {
  local res = {}
  foreach (armyId in curArmiesList.value) {
    local configs = squadsCfgById.value?[armyId]
    local presentations = squadsPresentation?[armyId]
    local squadsList = (squadsByArmies.value?[armyId] ?? {})
      .values()
      .map(function(squad) {
        local squadGuid = squad.guid
        local squadId = squad.squadId
        local config = configs?[squadId]
        local presentation = presentations?[squadId]
        local curVehicle = vehicleBySquad.value?[squadGuid]
        local icon = config?.icon ?? ""
        local nameLocId = (config?.nameLocId ?? "") != "" ? config.nameLocId
          : presentation?.nameLocId ?? "squad/defaultName"
        local titleLocId = (config?.titleLocId ?? "") != "" ? config.titleLocId
          : presentation?.titleLocId ?? "squad/defaultTitle"
        local manageLocId = (config?.manageLocId ?? "") != "" ? config.manageLocId
          : presentation?.manageLocId ?? titleLocId
        local optional = {}
        if ((config?.battleExpBonus ?? 0) > 0) {
          optional.premIcon <- armiesPresentation?[armyId].premIcon
          optional.battleExpBonus <- config.battleExpBonus
        }
        return squad.__merge({
          image = config?.image
          icon = icon
          nameLocId = nameLocId
          titleLocId = titleLocId
          manageLocId = manageLocId
          squadType = config?.squadType
          vehicle = objInfoByGuid.value?[curVehicle?.guid]
          vehicleType = config?.vehicleType ?? ""
          size = config?.size ?? 1 //base squad size
          squadSize = soldiersBySquad.value?[squadGuid].len() ?? 0
          capacity = config?.size ?? 0
        }).__update(optional)
      })
      .sort(sortByIndex)
    res[armyId] <- squadsList
  }
  return res
})

local armySquadsById = ::Computed(@() squadsByArmy.value.map(@(squads)
  squads.reduce(@(res, s) res.__update({ [s.squadId] = s }), {})))

local unlockedSquadsByArmy = ::Computed(@()
  squadsByArmy.value.map(@(sqList) sqList.filter(@(s) (s?.locked ?? false) == false)))

local curUnlockedSquads = ::Computed(@() unlockedSquadsByArmy.value?[curArmy.value] ?? [])

local allUnlockedSquadsSoldiers = ::Computed(function() {
  local res = {}
  foreach (armyId in curArmiesList.value)
    res[armyId] <- (soldiersByArmies.value?[armyId] ?? {})
      .filter(function(soldier) {
        local squadGuid = getLinkedSquadGuid(soldier)
        return !(curCampSquads.value?[squadGuid].locked ?? true)
      })
      .values()
  return res
})

local curUnlockedSquadsSoldiers = ::Computed(@()
  allUnlockedSquadsSoldiers.value?[curArmy.value] ?? [])

local chosenSquadsByArmy = ::Computed(function() {
  local res = {}
  foreach (armyId in curArmiesList.value) {
    local squadsLimits = limitsByArmy.value?[armyId] ?? armyLimitsDefault
    local { maxSquadsInBattle, maxInfantrySquads, maxVehicleSquads } = squadsLimits
    local squadsList = []
    foreach (squad in unlockedSquadsByArmy.value?[armyId] ?? []) {
      if (squad.vehicleType != "") {
        if (maxVehicleSquads <= 0)
          continue
        maxVehicleSquads--
      }
      else {
        if (maxInfantrySquads <= 0)
          continue
        maxInfantrySquads--
      }

      squadsList.append(squad)
      maxSquadsInBattle--
      if (maxSquadsInBattle <= 0)
        break
    }
    res[armyId] <- squadsList
  }
  return res
})

local curChoosenSquads = ::Computed(@() chosenSquadsByArmy.value?[curArmy.value] ?? [])

local curSquadId = Watched(null)

local isSquadCalculatedChange = false
local function recalcCurSquad() {
  local squadId = null
  local choosenSquads = curChoosenSquads.value
  if ((choosenSquads ?? []).len() > 0) {
    squadId = playerSelectedSquads.value?[curArmy.value]
    if (!squadId || choosenSquads.findindex(@(s) s.squadId == squadId) == null)
      squadId = choosenSquads[0].squadId
  }
  isSquadCalculatedChange = true
  curSquadId(squadId)
  isSquadCalculatedChange = false
}
recalcCurSquad()
frp.subscribe([curChoosenSquads, curArmy], @(_) recalcCurSquad())

curSquadId.subscribe(function(squadId) {
  if (isSquadCalculatedChange)
    return
  local army = curArmy.value
  if (army && squadId != playerSelectedSquads.value?[army]) {
    setPlayerSelectedSquads(playerSelectedSquads.value.__merge({ [army] = squadId}))
  }
})

local function getModSlots(item /*full item info recived via objInfoByGuid*/) {
  local res = []
  foreach(slotType, scheme in item?.equipScheme ?? {})
    if ((scheme?.listSize ?? 0) <= 0) //do not support modes list as item mods yet.
      res.append({
        slotType = slotType
        scheme = scheme
        equipped = getObjectsByLink(curCampItems.value, item.guid, slotType)?[0].guid
      })
  return res
}

local getScheme = @(item, slotType) item?.equipScheme[slotType]

local curSquad = ::Computed(@()
  curUnlockedSquads.value.findvalue(@(s) s.squadId == curSquadId.value))

local curSquadParams = ::Computed(@()
  squadsParams.value?[curArmy.value][curSquadId.value])

local curSquadSoldiersInfo = ::Computed(function() {
  local squad = curSquad.value
  return squad != null
    ? getObjectsByLinkSorted(curCampSoldiers.value, squad.guid, "squad")
    : []
})

local armoryByArmy = ::Computed(@() itemsByArmies.value
  .map(@(list) list.filter(@(item) item.links.len() == 1)
    .values()))

local curArmory = ::Computed(@() armoryByArmy.value?[curArmy.value] ?? [])

local itemCountByArmy = ::Computed(function() {
  local res = {}
  foreach(armyId in curArmiesList.value) {
    local armyCount = {}
    foreach (item in itemsByArmies.value?[armyId] ?? []) {
      local { basetpl } = item
      armyCount[basetpl] <- (armyCount?[basetpl] ?? 0) + item.count
    }
    res[armyId] <- armyCount
  }
  return res
})

local curCampItemsCount = ::Computed(function() {
  local res = {}
  foreach(armyCount in itemCountByArmy.value) {
    if (res.len() == 0) {
      res = clone armyCount
      continue
    }
    foreach(basetpl, count in armyCount)
      res[basetpl] <- (res?[basetpl] ?? 0) + count
  }
  return res
})

local curVehicle = ::Computed(@() vehicleBySquad.value?[curSquad.value?.guid].guid)

local getEquippedItemGuid = @(itemsList, soldierGuid, slotType, slotId)
  getLinkedObjects(itemsList, soldierGuid)
    .findvalue(@(link) link.type == slotType && ((slotId ?? -1) == -1 || slotId == getItemIndex(link.value)))
    ?.key

local getSoldierByGuid = @(guid)
  curCampSoldiers.value?[guid] ?? cratesContent.value?.content_data.soldiers[guid]

local changeSquadOrder = @(armyId, orderedGuids)
  changeOrderQueue({
    uid = $"{armyId}/squads"
    logId = "squads"
    listGetter = @() squadsByArmy.value?[armyId] ?? []
    order = orderedGuids
    listWatch = squads
    request = @(orderedGuids, cb) set_squad_order(armyId, orderedGuids, cb)
  })

local function addArmyExp(armyId, exp, cb = null) {
  add_army_exp(armyId, exp, cb)
}

local function setVehicleToSquad(squadGuid, vehicleGuid) {
  if (vehicleBySquad.value?[squadGuid] == vehicleGuid)
    return

  set_vehicle_to_squad(vehicleGuid, squadGuid)
}

local function dropAfterBattleCrate(armyId = null, crateId = null, cb = null) {
  if (armyId == null)
    armyId = curArmiesList.value?[rand() % (curArmiesList.value.len() || 1)]
  local function handleResult(res, cb2) {
    if ("error" in res)
      return
    if (cb2)
      cb2(res.unseen)
  }
  openCrate.dropAfterBattleCrate(armyId, crateId, @(res) handleResult(res, cb))
}

local function resetProfile() {
  reset_profile(function (res) {
    debugTableData(res)
  })
}

local getSoldierItemSlots = @(guid) getLinkedObjects(curCampItems.value, guid)
  .map(@(_) { item = _.value, slotType = _.type, slotId = getItemIndex(_.value) })

local getSoldierItem = @(guid, slot)
  objInfoByGuid.value?[getObjectsByLink(curCampItems.value, guid, slot)?[0].guid]

local function getDemandingSlots(ownerGuid, slotType) {
  local equipScheme = objInfoByGuid.value?[ownerGuid].equipScheme ?? {}
  local equipGroup = equipScheme[slotType]?.atLeastOne ?? ""
  return equipGroup != ""
    ? equipScheme
        .filter(@(s) s?.atLeastOne == equipGroup)
        .map(@(_, slotType) getEquippedItemGuid(curCampItems.value, ownerGuid, slotType, null)) //lists with atLeastOne does not supported yet
    : {}
}

local function getDemandingSlotsInfo(ownerGuid, slotType) {
  local equipGroup = objInfoByGuid.value?[ownerGuid].equipScheme[slotType].atLeastOne ?? ""
  return equipGroup != "" ? ::loc($"equipDemand/{equipGroup}") : ""
}

local maxCampaignLevel = ::Computed(@() armies.value.reduce(@(v,camp) max(v, camp?.level ?? 0), 0))

console.register_command(function() {
  setCurCampaign(null)
  setCurArmies(null)
}, "meta.resetCurCampaign")

console.register_command(@() dropAfterBattleCrate(), "meta.dropAfterBattle")
console.register_command(@() dropAfterBattleCrate(curArmy.value), "meta.dropAfterBattleCurArmy")
console.register_command(@(crateId) dropAfterBattleCrate(curArmy.value, crateId), "meta.dropCrate")
console.register_command(@() update_profile(), "meta.update")
console.register_command(@() soldiers_regenerate_view(), "meta.soldiersRegenerateView")
console.register_command(function() {
  local tmpArmies = clone curArmies.value
  delete tmpArmies?[curCampaign.value]
  setCurArmies(tmpArmies)
}, "meta.selectArmyScene")
console.register_command(@() add_items_by_type(curArmy.value, "vehicle", 1), "meta.addAllVehicles")
console.register_command(@() add_items_by_type(curArmy.value, "semiauto", 1), "meta.addAllSemiautos")
console.register_command(@() add_items_by_type(curArmy.value, "shotgun", 1), "meta.addAllShotguns")
console.register_command(@() add_items_by_type(curArmy.value, "boltaction", 1), "meta.addAllSniperBoltactions")
console.register_command(@() add_items_by_type(curArmy.value, "semiauto_sniper", 1), "meta.addAllSniperSemiautos")
console.register_command(@() add_items_by_type(curArmy.value, "boltaction_noscope", 1), "meta.addAllBoltactions")
console.register_command(@() add_items_by_type(curArmy.value, "launcher", 1), "meta.addAllRocketLaunchers")
console.register_command(@() add_items_by_type(curArmy.value, "mgun", 1), "meta.addAllMachineguns")
console.register_command(@() add_items_by_type(curArmy.value, "submgun", 1), "meta.addAllSubmachineguns")
console.register_command(@() add_items_by_type(curArmy.value, "assault_rifle", 1), "meta.addAllAssaultrifles")
console.register_command(@() add_items_by_type(curArmy.value, "flaregun", 1), "meta.addAllFlareguns")
console.register_command(@() add_items_by_type(curArmy.value, "mortar", 1), "meta.addAllMortars")
console.register_command(@() add_items_by_type(curArmy.value, "flamethrower", 1), "meta.addAllFlamethrowers")
console.register_command(@() add_items_by_type(curArmy.value, "scope", 1), "meta.addAllScopes")
console.register_command(@() add_items_by_type(curArmy.value, "sideweapon", 1), "meta.addAllPistols")
console.register_command(@() add_items_by_type(curArmy.value, "medkits", 1), "meta.addAllMedkits")
console.register_command(@() add_items_by_type(curArmy.value, "grenade", 1), "meta.addAllGrenades")
console.register_command(@() add_items_by_type(curArmy.value, "reapair_kit", 1), "meta.addAllRepairKits")
console.register_command(@() add_items_by_type(curArmy.value, "itemparts", 100), "meta.addAllItemParts")
console.register_command(@(exp) addArmyExp(curArmy.value, exp), "meta.addCurArmyExp")

return {
  resetProfile
  armies
  curCampSquads
  curCampItems
  curCampSoldiers
  getSoldierLook = @(guid) soldiersLook.value?[guid]
  curSquadId
  curUnlockedSquads
  allUnlockedSquadsSoldiers
  curUnlockedSquadsSoldiers
  chosenSquadsByArmy
  curChoosenSquads
  limitsByArmy
  armyLimitsDefault
  curArmyLimits
  curSquad
  curSquadParams
  curSquadSoldiersInfo
  curCampaign
  curCampItemsCount
  itemCountByArmy
  playerSelectedSquads
  objInfoByGuid
  getModSlots
  getScheme
  getSoldierByGuid
  getSoldierItemSlots
  getSoldierItem
  getDemandingSlots
  getDemandingSlotsInfo
  maxCampaignLevel

  setCurArmies
  curArmies
  squadsByArmy
  armySquadsById
  unlockedSquadsByArmy

  playerSelectedArmy
  curArmy
  curArmyData
  curArmies_list = curArmiesList
  armoryByArmy
  curArmory
  curVehicle
  getSquadConfig
  mteam
  allAvailableArmies

  getItemIndex
  vehicleBySquad
  getSoldiersByArmy = @(armyId) soldiersByArmies.value?[armyId] ?? {}
  soldiersBySquad
  getItemOwnerGuid
  getItemOwnerSoldier

  changeSquadOrder
  addArmyExp
  setVehicleToSquad
  getEquippedItemGuid
  dropAfterBattleCrate
  openCrate = @(crateId, armyId) openCrate.openCrate(crateId, armyId, armies)
}
 