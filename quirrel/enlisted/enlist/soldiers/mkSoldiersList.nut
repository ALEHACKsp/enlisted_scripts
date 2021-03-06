local cursors = require("ui/style/cursors.nut")
local scrollbar = require("daRg/components/scrollbar.nut")
local STATUS = require("model/readyStatus.nut")
local { slotBaseSize, smallPadding, bigPadding, blurBgColor, blurBgFillColor,
  scrollbarParams, listCtors, blockedTxtColor
} = require("enlisted/enlist/viewConst.nut")
local { bgColor, txtColor } = listCtors
local { note, txt } = require("enlisted/enlist/components/defcomps.nut")
local mkSoldierCard = require("mkSoldierCard.nut")


local slotWithPadding = [slotBaseSize[0], slotBaseSize[1] + bigPadding]

local blockWithHeader = @(header, content, size) {
  flow = FLOW_VERTICAL
  gap = smallPadding
  size = size
  children = [
    note(header)
    content
  ]
}

local mkSoldierSlot = ::kwarg(function(soldier, idx, curSoldierIdxWatch,
  canDeselect = true, addCardChild = null,
  soldiersReadyWatch = Watched(null), defSoldierGuidWatch = Watched(null)
) {
  local isSelectedWatch = ::Computed(function() {
    if (curSoldierIdxWatch.value == idx)
      return true
    local sGuid = defSoldierGuidWatch.value
    return sGuid != null && soldier.guid == sGuid
  })

  local stateFlags = ::Watched(0)
  local group = ::ElemGroup()
  local soldiersReadyInfo = soldiersReadyWatch.value
  return function() {
    local sf = stateFlags.value
    local soldierStatus = soldiersReadyInfo?[soldier.guid] ?? STATUS.READY
    local hasWeaponWarning = (soldierStatus & STATUS.NOT_READY_BY_EQUIP) != 0
    local isSelected = isSelectedWatch.value

    local chContent = {
      xmbNode = ::XmbNode()
      padding = [0, bigPadding, 0, 0]
      children = mkSoldierCard({
        idx = idx
        soldierInfo = soldier
        size = slotBaseSize
        group = group
        sf = sf
        isSelected = isSelected
        isFaded = soldierStatus != STATUS.READY
        isClassRestricted = (soldierStatus & STATUS.TOO_MUCH_CLASS) != 0
        hasAlertStyle = hasWeaponWarning
        hasWeaponWarning = hasWeaponWarning
        addChild = @(soldierInfo, isChildSelected) [
          addCardChild?(soldierInfo, isChildSelected)
        ]
      })
    }

    return {
      watch = [soldiersReadyWatch, isSelectedWatch, stateFlags]
      group = group
      size = slotWithPadding
      key = $"slot{soldier?.guid}{idx}"

      behavior = Behaviors.Button
      onElemState = @(s) stateFlags(s)
      onClick = function() {
        if (soldier?.canSpawn ?? true) {
          defSoldierGuidWatch(null)
          curSoldierIdxWatch(canDeselect && idx == curSoldierIdxWatch.value ? null : idx)
        }
      }

      children = chContent
    }
  }
})

local function mkSoldiersBlock(params) {
  local { soldiersListWatch, curSoldierIdxWatch } = params
  local soldiersList = @() {
    watch = [soldiersListWatch, curSoldierIdxWatch]
    size = [slotBaseSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    function onClick() {
      if (params?.canDeselect ?? false)
        curSoldierIdxWatch(null)
    }
    children = soldiersListWatch.value.map(@(s, idx)
      mkSoldierSlot(params.__merge({ soldier = s, idx = idx })))
  }
  return blockWithHeader(::loc("menu/soldier"), soldiersList, SIZE_TO_CONTENT)
}

local vehicleBlock = ::kwarg(@(hasVehicleWatch, curVehicleUi) @() {
  watch = hasVehicleWatch
  size = [flex(), SIZE_TO_CONTENT]
  margin = hasVehicleWatch.value ? [0, 0, bigPadding, 0] : 0
  children = hasVehicleWatch.value
    ? blockWithHeader(::loc("menu/vehicle"), curVehicleUi, [flex(), SIZE_TO_CONTENT])
    : null
})

local soldiersListStyle = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = bigPadding
  flow = FLOW_VERTICAL
}

local mkMainSoldiersBlock = @(params) soldiersListStyle.__merge({
  size = [SIZE_TO_CONTENT, flex()]
  children = [
    params?.headerBlock
    "hasVehicleWatch" in params ? vehicleBlock(params) : null
    mkSoldiersBlock(params)
    params?.bottomObj
  ]
})

local mkTrainingSoldierSlot = ::kwarg(function(soldier, idx, onClickCb) {
  local stateFlags = ::Watched(0)
  local group = ::ElemGroup()
  return @() {
    watch = stateFlags
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() onClickCb(soldier)
    group = group
    children = mkSoldierCard({
      idx = idx
      soldierInfo = soldier
      hasAlertStyle = soldier?.hasAlertStyle ?? true
      sf = stateFlags.value
      group = group
    })
  }
})

local mkTraininSoldiersList = ::kwarg(@(soldiersList, onSlotClickCb, width) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = soldiersList.len() > 0
    ? wrap(soldiersList.map(@(soldier, idx)
        mkTrainingSoldierSlot({
          soldier = soldier
          idx = idx
          onClickCb = onSlotClickCb
        })),
        {
          width = width,
          hGap = bigPadding,
          vGap = bigPadding
        })
    : txt(::loc("menu/noAvailableSoldiers")).__update({
        margin = [0, bigPadding]
        color = blockedTxtColor
      })
})

local mkTraininSoldiersBlock = @(params)
  @() {
    watch = [params.reserveSoldiersWatch, params.squadsSoldiersWatch]
    size = [SIZE_TO_CONTENT, flex()]
    children = scrollbar.makeVertScroll({
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        blockWithHeader("{0} ({1})".subst(::loc("menu/reserve"), params.reserveSoldiersWatch.value.len()),
          mkTraininSoldiersList({
            soldiersList = params.reserveSoldiersWatch.value
            onSlotClickCb = params.onSlotClickCb
            width = params.width
          }),
          [params.width, SIZE_TO_CONTENT])
        blockWithHeader("{0} ({1})".subst(::loc("menu/soldiersAssignedToSquad"), params.squadsSoldiersWatch.value.len()),
          mkTraininSoldiersList({
            soldiersList = params.squadsSoldiersWatch.value
            onSlotClickCb = params.onSlotClickCb
            width = params.width
          }),
          [params.width, SIZE_TO_CONTENT])
      ]
    }, scrollbarParams)
  }.__update(soldiersListStyle)

local function soldiersListButton(mkContent, override = {}, tooltip = "") {
  local stateFlags = ::Watched(0)
  return function() {
    local sf = stateFlags.value
    local contentColor = txtColor(sf, false)
    return {
      watch = stateFlags
      size = [slotBaseSize[0], SIZE_TO_CONTENT]
      rendObj = ROBJ_SOLID
      color = bgColor(sf, false)
      behavior = Behaviors.Button
      onElemState = @(s) stateFlags(s)
      onHover = tooltip.len() > 0
        ? @(on) cursors.tooltip.state(on ? tooltip : null)
        : null
      children = mkContent(sf, contentColor)
    }.__update(override)
  }
}

return {
  mkMainSoldiersBlock = mkMainSoldiersBlock
  //TODO: Need to make mkTraininSoldiersBlock block as separate UI comp
  trainingList = mkTraininSoldiersBlock
  soldiersListButton = soldiersListButton
}
 