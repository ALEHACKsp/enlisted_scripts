local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local {
  vehicles, squadsWithVehicles, viewVehicle, selectVehicle,
  selectParams, curSquadId, setCurSquadId, CANT_USE
} = require("vehiclesListState.nut")
local { getSquadConfig } = require("enlisted/enlist/soldiers/model/state.nut")

local { bigPadding, blurBgColor, blurBgFillColor, vehicleListCardSize } = require("enlisted/enlist/viewConst.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local scrollbar = require("daRg/components/scrollbar.nut")
local vehiclesListCard = require("vehiclesListCard.ui.nut")
local vehicleDetails = require("vehicleDetails.ui.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local mkHeader = require("enlisted/enlist/components/mkHeader.nut")
local mkToggleHeader = require("enlisted/enlist/components/mkToggleHeader.nut")
local { mkCurSquadsList } = require("enlisted/enlist/soldiers/mkSquadsList.nut")


local close = @() selectParams(null)
local showNotAvailable = ::Watched(false)
selectParams.subscribe(@(_) showNotAvailable(false))

local function createSquadHandlers(squads) {
  squads.each(@(squad, idx)
    squad.__update({
      onClick = @() setCurSquadId(squad.squadId)
      isSelected = ::Computed(@() curSquadId.value == squad.squadId)
    })
  )
}

local notAvailableHeader = mkToggleHeader(showNotAvailable, ::loc("header/notAvailableVehicles"))

local function vehiclesList() {
  local children = vehicles.value.map(@(item) vehiclesListCard({
    item = item
    onClick = @(item) viewVehicle(item)
    onDoubleClick = @(item) selectVehicle(item)
  }))
  local unavailableIdx = vehicles.value.findindex(@(v) (v.status & CANT_USE) != 0)
  if (unavailableIdx != null) {
    children.insert(unavailableIdx, notAvailableHeader)
    if (!showNotAvailable.value)
      children = children.slice(0, unavailableIdx + 1)
  }
  return {
    watch = [vehicles, showNotAvailable]
    size = [vehicleListCardSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = children
  }
}

local vehiclesBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = bigPadding
  flow = FLOW_VERTICAL
  children = scrollbar.makeVertScroll(vehiclesList, {
    size = [SIZE_TO_CONTENT, flex()]
    needReservePlace = false
  })
}

local function mkSquadName(squadId, armyId) {
  local squadConfig = getSquadConfig(squadId, armyId)
  return squadConfig != null
    ? txt(::loc(squadConfig?.titleLocId ?? ""))
    : null
}

local selectVehicleContent = {
  size = flex()
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    @() {
      watch = selectParams
      children = mkSquadName(selectParams.value?.squadId, selectParams.value?.armyId)
    }
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        mkCurSquadsList({
          curSquadsList = squadsWithVehicles
          curSquadId = curSquadId
          createHandlers = createSquadHandlers
        })
        vehiclesBlock
        { size = flex() }
        vehicleDetails
      ]
    }
  ]
}

local function selectVehicleScene() {
  local borders = safeAreaBorders.value
  return {
    watch = safeAreaBorders
    size = [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    padding = [borders[0], 0, 0, 0]
    children = [
      @() {
        size = [flex(), SIZE_TO_CONTENT]
        watch = selectParams
        children = mkHeader({
          armyId = selectParams.value?.armyId
          textLocId = "Choose vehicle"
          closeButton = closeBtnBase({ onClick = close })
        })
      }
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [0, borders[1], borders[2], borders[3]]
        children = selectVehicleContent
      }
    ]
  }
}

local function open() {
  sceneWithCameraAdd(selectVehicleScene, "vehicles")
}

if (selectParams.value)
  open()

selectParams.subscribe(function(p) {
  if (p == null)
    sceneWithCameraRemove(selectVehicleScene)
  else
    open()
})

return {
  open = ::kwarg(@(armyId, squadId) selectParams({ armyId = armyId, squadId = squadId }))
  close = close
} 