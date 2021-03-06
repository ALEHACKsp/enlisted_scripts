local { bigPadding, activeTxtColor, noteTxtColor } = require("enlisted/enlist/viewConst.nut")
local colorize = require("enlist/colorize.nut")
local textButton = require("enlist/components/textButton.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")
local blinkingIcon = require("enlisted/enlist/components/blinkingIcon.nut")
local { curArmy, curSquadId, curSquad, curSquadParams, curVehicle, objInfoByGuid
} = require("model/state.nut")
local { curArmyReserve, needSoldiersManageBySquad } = require("model/reserve.nut")
local { mkSoldiersDataList } = require("model/collectSoldierData.nut")
local selectVehicleScene  = require("enlisted/enlist/vehicles/selectVehicleScene.nut")
local { notChoosenPerkSoldiers, perksData } = require("model/soldierPerks.nut")
local { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")
local { unseenSquadsVehicle } = require("enlisted/enlist/vehicles/unseenVehicles.nut")
local { curSoldierIdx, soldiersList, vehicleCapacity, curSoldierInfo
} = require("model/squadInfoState.nut")
local { curSquadSoldiersStatus } = require("model/readySoldiers.nut")
local { mkMainSoldiersBlock, soldiersListButton } = require("mkSoldiersList.nut")
local mkCurVehicle = require("mkCurVehicle.nut")
local { newPerksIcon } = require("components/soldiersUiComps.nut")
local squadHeader = require("components/squadHeader.nut")
local deliveriesState = require("enlisted/enlist/deliveries/deliveriesState.nut")
local { hasDeliveries } = require("enlisted/globals/wipFeatures.nut")
local { hasSquadVehicle } = require("enlisted/enlist/vehicles/vehiclesListState.nut")
local squadsParams = require("model/squadsParams.nut")
local { openChooseSoldiersWnd } = require("model/chooseSoldiersState.nut")
local { curUnseenUpgradesBySoldier } = require("model/unseenUpgrades.nut")


local vehicleInfo = ::Computed(@() objInfoByGuid.value?[curVehicle.value])

local function openChooseVehicle(event) {
  if (event.button < 0 || event.button > 2)
    return
  selectVehicleScene.open({ armyId = curArmy.value, squadId = curSquadId.value })
}

local mkAlertInfo = @(soldierInfo, isSelected) {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = newPerksIcon(soldierInfo?.guid, isSelected,
    ::Computed(@() (notChoosenPerkSoldiers.value?[soldierInfo?.guid] ?? 0)
      + (unseenSoldiersWeaponry.value?[soldierInfo?.guid].len() ?? 0)
      + (curUnseenUpgradesBySoldier.value?[soldierInfo?.guid] ?? 0)))
}

local deliveriesBtn = hasDeliveries ? textButton.SmallFlat( ::loc("Recruitment"), deliveriesState.openSoldiersScene,
  {
    hplace = ALIGN_CENTER
    padding = [bigPadding, 2 * bigPadding]
  }
) : null

local allowedReserve = ::Computed(function() {
  local { maxClasses = null } = curSquadParams.value
  if (maxClasses == null)
    return 0
  return curArmyReserve.value.reduce(@(res, s) (maxClasses?[s.sClass] ?? 0) > 0 ? res + 1 : res, 0)
})

local function reserveAvailableBlock() {
  local res = { watch = allowedReserve }
  local count = allowedReserve.value
  if (count <= 0)
    return res
  return res.__update({
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    margin = [0, 0, bigPadding * 2, 0]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = ::loc("squad/reserveAvailable", { count, countColored = colorize(activeTxtColor, count) })
    color = noteTxtColor
    font = Fonts.tiny_text
  })
}

local manageSoldiersBtn = function() {
  local curSquadGuid = curSquad.value?.guid
  local needSoldiersManage = needSoldiersManageBySquad.value?[curSquadGuid] ?? false
  return {
    watch = [needSoldiersManageBySquad, curSquad]
    children = [
      soldiersListButton(
        @(sf, color) {
          rendObj = ROBJ_TEXTAREA
          size = [flex(), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          text = ::loc("soldier/manageButton")
          color = color
          font = Fonts.small_text
          halign = ALIGN_CENTER
        },
        {
          padding = [bigPadding, 2 * bigPadding]
          onClick = @() openChooseSoldiersWnd(curSquad.value?.guid, curSoldierInfo.value?.guid)
        },
        needSoldiersManage ? ::loc("msg/canAddSoldierToSquad") : "")
      needSoldiersManage ? unseenSignal(0.7) : null
    ]
  }
}

local curSquadUnseenVehicleCount = Computed(@() unseenSquadsVehicle.value?[curSquad.value?.guid].len() ?? 0)
local function unseenVehiclesMark() {
  local res = { watch = curSquadUnseenVehicleCount }
  if (curSquadUnseenVehicleCount.value > 0)
    res.__update(blinkingIcon("arrow-up", curSquadUnseenVehicleCount.value))
  return res
}

return function() {
  local res = { watch = [curSquadId, perksData] }
  if (curSquadId.value == null)
    return res

  local sqParamsWatch = ::Computed(@() squadsParams.value?[curArmy.value][curSquadId.value])
  if (sqParamsWatch.value == null)
    return res

  local squadListWatch = mkSoldiersDataList(soldiersList)
  return res.__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = mkMainSoldiersBlock({
      soldiersListWatch = squadListWatch
      hasVehicleWatch = ::Computed(@() hasSquadVehicle(curSquad.value))
      curSoldierIdxWatch = curSoldierIdx
      soldiersReadyWatch = curSquadSoldiersStatus
      curVehicleUi = mkCurVehicle({
        openChooseVehicle = openChooseVehicle
        vehicleInfo = vehicleInfo
        child = unseenVehiclesMark
      })
      canDeselect = true
      addCardChild = mkAlertInfo
      headerBlock = squadHeader({
        curSquad = curSquad
        curSquadParams = curSquadParams
        soldiersList = soldiersList
        vehicleCapacity = vehicleCapacity
        soldiersStatuses = curSquadSoldiersStatus
      })
      bottomObj = @() {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [bigPadding, 0, 0, 0]
        flow = FLOW_VERTICAL
        children = [
          reserveAvailableBlock
          manageSoldiersBtn
          deliveriesBtn
        ]
      }
    })
  })
}
 