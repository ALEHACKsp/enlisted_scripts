local msgbox = require("ui/components/msgbox.nut")
local {
  getLinksByType, getObjectsByLink, getLinkedArmyName
} = require("enlisted/enlist/meta/metalink.nut")
local { itemsByArmies, armies } = require("enlisted/enlist/meta/profile.nut")
local { unlockedSquadsByArmy, setVehicleToSquad } = require("enlisted/enlist/soldiers/model/state.nut")
local {
  prepareItems, addShopItems, findItemByGuid, putToStackTop
} = require("enlisted/enlist/soldiers/model/items_list_lib.nut")
local allowedVehicles = require("allowedVehicles.nut")
local { squadsCfgById } = require("enlisted/enlist/soldiers/model/config/squadsConfig.nut")
local { armiesRewards } = require("enlisted/enlist/campaigns/armiesConfig.nut")

local NEED_RESEARCH_USE          = 0x01 //need unlock for cur squad to use
local CAN_RECEIVE_BY_ARMY_LEVEL  = 0x02
local LOCKED                     = 0x04
local CANT_USE                   = 0x08 //never can use for this squad
local CAN_USE                    = 0

local viewVehicle = persist("viewVehicle", @() Watched(null))
local selectParams = persist("selectParams", @() Watched(null))

local curSquad = ::Computed(function() {
  if (selectParams.value == null)
    return null
  local { armyId, squadId } = selectParams.value
  return (unlockedSquadsByArmy.value?[armyId] ?? []).findvalue(@(s) s.squadId == squadId)
})
local curSquadArmy = ::Computed(@() curSquad.value == null ? null : getLinkedArmyName(curSquad.value))
local curSquadArmyLevel = ::Computed(@() armies.value?[curSquadArmy.value].level ?? 0)

local curVehicleType = ::Computed(function() {
  if (selectParams.value == null)
    return null
  local { armyId, squadId } = selectParams.value
  return squadsCfgById.value?[armyId][squadId].vehicleType
})

local getVehicleSquad = @(vehicle) getLinksByType(vehicle, "curVehicle")?[0]
local findSelVehicle = @(vehicleList, squadGuid) getObjectsByLink(vehicleList, squadGuid, "curVehicle")?[0].guid

local hasAllBits = @(mask, checkMask) (mask & checkMask) == checkMask

local function calcVehicleStatus(vehicle, curSquadAllowedVehicles, armyRewards, armyLevel) {
  local status = CAN_USE
  local statusText = ""
  local { basetpl } = vehicle
  local allowed = curSquadAllowedVehicles?[basetpl]
  local receiveLevel = (armyRewards?[basetpl] ?? []).findvalue(@(level) level > armyLevel) ?? -1

  if (allowed == null)
    status = status | CANT_USE
  else if (!allowed)
    status = status | NEED_RESEARCH_USE
  if (vehicle?.isShopItem)
    status = status | LOCKED
  if (allowed != null && receiveLevel > 0)
    status = status | CAN_RECEIVE_BY_ARMY_LEVEL

  statusText = status & CANT_USE ? ::loc("hint/notAllowedForCurSquad")
    : hasAllBits(status, LOCKED | CAN_RECEIVE_BY_ARMY_LEVEL)
      ? ::loc("hint/receiveVehicleByCampaignRewards", { level = receiveLevel })
    : status & LOCKED ? ::loc("hint/unknowVehicleReceive")
    : status & NEED_RESEARCH_USE ? ::loc("vehicleSquadResearch")
    : ""
  return { status, statusText }
}

local vehicleSort = @(vehicles, curVehicle)
  vehicles.sort(@(a, b) (b == curVehicle) <=> (a == curVehicle)
    || a.status <=> b.status
    || a.tier <=> b.tier
    || a.basetpl <=> b.basetpl)

local vehicles = ::Computed(function() {
  local res = []
  local squadGuid = curSquad.value?.guid
  local vehicleType = curVehicleType.value
  if (squadGuid == null || vehicleType == null)
    return res

  local armyId = getLinkedArmyName(curSquad.value)
  local items = itemsByArmies.value?[armyId] ?? {}
  foreach(item in items) {
    if (item?.itemtype != "vehicle"
        || item?.itemsubtype != vehicleType
        || armyId != getLinkedArmyName(item))
      continue
    local ownerGuid = getVehicleSquad(item)
    if (!ownerGuid || ownerGuid == squadGuid)
      res.append(item)
  }

  local selectedGuid = findSelVehicle(res, squadGuid)
  res = prepareItems(res)
  if (selectedGuid != null)
    putToStackTop(res, items?[selectedGuid])
  addShopItems(res, armyId, @(tplId, tpl) tpl?.itemtype == "vehicle" && tpl?.itemsubtype == vehicleType)

  local curSquadAllowedVehicles = allowedVehicles.value?[armyId][curSquad.value?.squadId] ?? {}
  local armyRewards = armiesRewards.value?[armyId]
  local armyLevel = curSquadArmyLevel.value
  res = res.map(@(vehicle) vehicle.__merge(calcVehicleStatus(vehicle, curSquadAllowedVehicles, armyRewards, armyLevel)))
  vehicleSort(res, res.findvalue(@(v) v.guid == selectedGuid))
  return res
})

local selectedVehicle = ::Computed(function() {
  local vList = vehicles.value
  local squadGuid = curSquad.value?.guid
  if (!squadGuid || vList.len() == 0)
    return null

  local guid = findSelVehicle(vList.filter(@(v) v?.isShopItem != true), squadGuid)
  return guid ? findItemByGuid(vList, guid) : null
})

if (viewVehicle.value != null) {
  local cur = viewVehicle.value
  local new = cur?.isShopItem ? vehicles.value.findvalue(@(item) item?.basetpl == cur.basetpl)
    : cur?.guid ? findItemByGuid(vehicles.value, cur.guid)
    : cur ? vehicles.value[0]
    : null
  viewVehicle(new ?? selectedVehicle.value)
}
selectedVehicle.subscribe(@(v) viewVehicle(v))

local function selectVehicle(vehicle) {
  local { statusText } = vehicle
  if (statusText != "")
    return msgbox.show({ text = statusText })

  local squad = curSquad.value
  if (squad)
    setVehicleToSquad(squad.guid, vehicle?.guid)
  selectParams(null)
}

local hasSquadVehicle = @(squadCfg) (squadCfg?.vehicle ?? squadCfg?.startVehicle ?? "") != ""

local squadsWithVehicles = ::Computed(function() {
  local armyId = selectParams.value?.armyId
  if (!armyId)
    return null

  local armyConfig = squadsCfgById.value?[armyId]
  return (unlockedSquadsByArmy.value?[armyId] ?? [])
    .filter(@(squad) hasSquadVehicle(armyConfig?[squad.squadId]))
})

local curSquadId = ::Computed(@()
  selectParams.value?.squadId ?? squadsWithVehicles.value?[0].squadId)

local function setCurSquadId(id) {
  if (selectParams.value != null && selectParams.value.squadId != id)
    selectParams(@(params) params.__update({ squadId = id }))
}

return {
  viewVehicle
  selectedVehicle
  selectParams
  vehicles
  squadsWithVehicles
  curSquad
  curSquadId
  setCurSquadId
  curSquadArmy

  selectVehicle
  hasSquadVehicle

  NEED_RESEARCH_USE
  CAN_RECEIVE_BY_ARMY_LEVEL
  LOCKED
  CANT_USE
  CAN_USE
} 