local unseenSignal = require("enlist/components/unseenSignal.nut")(0.7)
local spinner = require("enlist/components/spinner.nut")({ height = ::hdpx(50) })
local msgbox = require("enlist/components/msgbox.nut")
local { curArmy } = require("enlisted/enlist/soldiers/model/state.nut")
local {
  bigPadding, blurBgColor, blurBgFillColor, smallPadding,
  activeBgColor, defBgColor, slotBaseSize, scrollbarParams, listCtors
} = require("enlisted/enlist/viewConst.nut")
local {
  READY, TOO_MUCH_CLASS, NOT_FIT_CUR_SQUAD, NOT_READY_BY_EQUIP
} = require("model/readyStatus.nut")
local { note, noteTextArea } = require("enlisted/enlist/components/defcomps.nut")
local { PrimaryFlat, FAButton, SmallFlat, Flat } = require("enlist/components/textButton.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local {
  squadSoldiers, reserveSoldiers, selectedSoldierGuid, selectedSoldier, soldiersStatuses,
  applyAndClose, changeSoldierOrderByIdx, maxSoldiersInBattle, soldiersSquadParams,
  moveCurSoldier, soldierToReserveByIdx, curSoldierToReserve, curSoldierToSquad, getCanTakeSlots,
  dismissSoldier, isDismissInProgress, soldiersSquad, closeChooseSoldiersWnd
} = require("model/chooseSoldiersState.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local {
  getLinkedArmyName, getLinkedSquadGuid
} = require("enlisted/enlist/meta/metalink.nut")
local { curArmyReserve, curArmyReserveCapacity } = require("model/reserve.nut")
local { gameProfile } = require("model/config/gameProfile.nut")
local { hasPremium } = require("enlisted/enlist/currency/premium.nut")
local { mkSoldiersDataList } = require("model/collectSoldierData.nut")

local closeBtnBase = require("enlist/components/closeBtn.nut")
local { makeVertScroll } = require("daRg/components/scrollbar.nut")
local mkSoldierInfo = require("mkSoldierInfo.nut")
local squadHeader = require("components/squadHeader.nut")
local mkSoldierCard = require("mkSoldierCard.nut")
local mkValueWithBonus = require("enlisted/enlist/components/valueWithBonus.nut")
local mkHeader = require("enlisted/enlist/components/mkHeader.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")

local {
  unseenSoldiers, markSoldierSeen
} = require("model/unseenSoldiers.nut")


const NO_SOLDIER_SLOT_IDX = -1

local slotWithPadding = [slotBaseSize[0], slotBaseSize[1] + bigPadding]

local reserveAvailableSize = ::Computed(@() reserveSoldiers.value.findindex(@(s)
    (soldiersStatuses.value?[s.guid] ?? NOT_FIT_CUR_SQUAD) & NOT_FIT_CUR_SQUAD)
  ?? reserveSoldiers.value.len())

local curDropData = Watched(null)
local curDropTgtIdx = Watched(NO_SOLDIER_SLOT_IDX)
curDropData.subscribe(@(v) curDropTgtIdx(NO_SOLDIER_SLOT_IDX))

local moveParams = ::Computed(function() {
  local watch = null
  local idx = null
  local guid = selectedSoldierGuid.value
  if (guid != null)
    foreach(w in [squadSoldiers, reserveSoldiers]) {
      idx = w.value.findindex(@(s) s?.guid == guid)
      if (idx != null) {
        watch = w
        break
      }
    }

  local listSize = watch == squadSoldiers ? watch.value.len()
    : watch == reserveSoldiers ? reserveAvailableSize.value
    : 0
  local isAvailable = watch != null && idx < listSize
  return {
    canUp = isAvailable && idx > 0
    canDown = isAvailable && idx < listSize - 1
    canRemove = watch == squadSoldiers
    canTake = watch == reserveSoldiers
    takeAvailable = isAvailable && soldiersStatuses.value?[guid] == READY
      && squadSoldiers.value.findindex(@(s) s == null) != null
  }
})

local soldierToTake = ::Computed(function() {
  local dropIdx = curDropData.value?.soldierIdx
  if (dropIdx != null)
    return reserveSoldiers.value?[dropIdx - maxSoldiersInBattle.value]
  local selGuid = selectedSoldierGuid.value
  return reserveSoldiers.value.findvalue(@(s) s.guid == selGuid)
})

local slotsHighlight = ::Computed(function() {
  local soldier = soldierToTake.value
  return soldier == null ? [] : getCanTakeSlots(soldier, squadSoldiers.value)
})

local commonLimit = ::Computed(@() curArmyReserveCapacity.value
  - (hasPremium.value ? (gameProfile.value?.premiumBonuses.soldiersReserve ?? 0) : 0))
local premiumLimit = ::Computed(@() hasPremium.value ? curArmyReserveCapacity.value : null)
local function reserveCountBlock() {
  local res = { watch = reserveSoldiers }
  local reserveCount = reserveSoldiers.value.len()
  if (reserveCount <= 0)
    return res

  return res.__update({
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = ::hdpx(5)
    margin = [0, 0, bigPadding, 0]
    children = [
      note(::loc("squad/reserveAmount", { count = reserveCount }))
      mkValueWithBonus(commonLimit, premiumLimit)
    ]
  })
}

local buttonOk = PrimaryFlat(::loc("Ok"), applyAndClose, { margin = 0, hplace = ALIGN_RIGHT })

local getMoveDirSameList = @(idx, dropIdx, targetIdx)
  dropIdx < idx && targetIdx >= idx ? -1
    : dropIdx > idx && targetIdx <= idx ? 1
    : 0

local function soldierDragAnim(idx, stateFlags, content, chContent, fixedSlots) {
  local watch = content?.watch ?? []
  if (typeof watch != "array")
    watch = [watch]
  watch.append(curDropData, curDropTgtIdx)

  local dropIdx = curDropData.value?.soldierIdx ?? -1
  local targetIdx = curDropTgtIdx.value
  local moveDir = 0
  if (targetIdx >= 0 && dropIdx >= 0)
    if (idx < fixedSlots)
      moveDir = dropIdx < fixedSlots && targetIdx < fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx) : 0
    else
      moveDir = dropIdx >= fixedSlots && targetIdx >= fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx)
        : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx ? 1
        : 0

  return content.__update({
    watch = watch
    behavior = Behaviors.DragAndDrop
    canDrop = @(data) data?.dragid == "soldier"
    dropData = "dropData" in content ? content.dropData : { soldierIdx = idx, dragid = "soldier" }
    onDragMode = @(on, data) curDropData(on ? data : null)
    onElemState = function(sf) {
      stateFlags(sf)
      if (!curDropData.value || curDropData.value.soldierIdx == idx)
        return
      if (sf & S_ACTIVE)
        curDropTgtIdx(idx)
      else if (curDropTgtIdx.value == idx)
        curDropTgtIdx(NO_SOLDIER_SLOT_IDX)
    }
    transform = {}
    children = chContent.__update({
      transform = idx == dropIdx ? {} : { translate = [0, moveDir * slotWithPadding[1]] }
      transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
    })
  })
}

local highlightBorder = {
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = ::hdpx(1)
  borderColor = 0xFFFFFFFF
}

local function mkEmptySlot(idx, tgtHighlight, hasBlink) {
  local group = ::ElemGroup()
  local onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  local isDropTarget = ::Computed(@() curDropTgtIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value)
  local needHighlight = ::Computed(@() tgtHighlight.value?[idx] ?? false)
  local stateFlags = ::Watched(0)

  return function() {
    local fixedSlots = maxSoldiersInBattle.value

    local content = {
      watch = [stateFlags, maxSoldiersInBattle, isDropTarget, needHighlight]
      group = group
      size = slotWithPadding
      key = $"emptySlot_{idx}"
      onDrop = onDrop
      dropData = null
      onClick = @() selectedSoldierGuid(null)
    }

    local chContent = {
      size = flex()
      padding = [0, 0, bigPadding, 0]
      children = {
        key = $"empty_slot_{idx}{hasBlink}"
        size = flex()
        rendObj = ROBJ_SOLID
        color = isDropTarget.value ? activeBgColor : defBgColor
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          {
            rendObj = ROBJ_DTEXT
            text = ::loc("squad/soldierFreeSlot")
            font = Fonts.small_text
            color = hasBlink
              ? listCtors.nameColor(0, isDropTarget.value)
              : listCtors.txtDisabledColor(0, isDropTarget.value)
            animations = hasBlink
              ? [{
                  prop = AnimProp.opacity, from = 0.4, to = 1, duration = 1,
                  play = true, loop = true, easing = Blink
                }]
              : null
          }
          needHighlight.value ? highlightBorder : null
        ]
      }
    }

    return soldierDragAnim(idx, stateFlags, content, chContent, fixedSlots)
  }
}

local unseenMark = @(soldierGuid) @() {
  watch = unseenSoldiers
  hplace = ALIGN_RIGHT
  children = (unseenSoldiers.value?[soldierGuid] ?? false) ? unseenSignal : null
}

local function mkSoldierSlot(soldier, idx, tgtHighlight, unseenObj = null) {
  local isSelectedWatch = ::Computed(@() selectedSoldierGuid.value == soldier.guid)
  local isDropTarget = ::Computed(@() idx < maxSoldiersInBattle.value && curDropTgtIdx.value == idx
    && (curDropData.value?.soldierIdx ?? -1) >= maxSoldiersInBattle.value)
  local needHighlight = ::Computed(@() tgtHighlight.value?[idx] ?? false)

  local soldierStatus = ::Computed(@() soldiersStatuses.value?[soldier.guid] ?? READY)
  local onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
  local stateFlags = ::Watched(0)
  local group = ::ElemGroup()
  return function() {
    local sf = stateFlags.value
    local fixedSlots = maxSoldiersInBattle.value
    local status = soldierStatus.value
    local isSelected = isSelectedWatch.value

    local content = {
      watch = [stateFlags, maxSoldiersInBattle, soldierStatus, isSelectedWatch, isDropTarget, needHighlight]
      xmbNode = ::XmbNode()
      group = group
      size = slotWithPadding
      key = $"slot{soldier?.guid}{idx}"
      onDrop = onDrop
      onClick = @() selectedSoldierGuid(soldier.guid == selectedSoldierGuid.value ? null : soldier.guid)
      onHover = function(on) {
        if (unseenObj != null && on)
          markSoldierSeen(curArmy.value, soldier?.guid)
      }
    }

    local chContent = {
      padding = [0, bigPadding, 0, 0]
      children = [
        mkSoldierCard({
          idx = idx
          soldierInfo = soldier
          size = slotBaseSize
          group = group
          sf = sf
          isSelected = isSelected || isDropTarget.value
          isFaded = status != READY
          isClassRestricted = status & TOO_MUCH_CLASS
          hasAlertStyle = status & NOT_FIT_CUR_SQUAD
          hasWeaponWarning = status & NOT_READY_BY_EQUIP
        })
        needHighlight.value ? highlightBorder : null
        unseenObj
      ]
    }

    return status & NOT_FIT_CUR_SQUAD
      ? content.__update({
          behavior = Behaviors.Button
          onElemState = @(sf) stateFlags(sf)
          transform = {}
          children = chContent
        })
      : soldierDragAnim(idx, stateFlags, content, chContent, fixedSlots)
  }
}

local function mkSoldiersList(soldiers, hasUnseen = false, idxOffset = ::Watched(0),
  tgtHighlight = ::Watched([]), slotsBlinkWatch = ::Watched(false)
) {
  local squadListWatch = mkSoldiersDataList(soldiers)
  return @() {
    watch = [squadListWatch, idxOffset, tgtHighlight, slotsBlinkWatch]
    size = [slotBaseSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    onClick = @() selectedSoldierGuid(null)
    children = squadListWatch.value.map(@(s, idx) s == null
      ? mkEmptySlot(idx + idxOffset.value, tgtHighlight, slotsBlinkWatch.value)
      : mkSoldierSlot(s, idx + idxOffset.value, tgtHighlight,
          hasUnseen ? unseenMark(s.guid) : null))
  }
}

local labelUnableToAdd = @(listWatch) function() {
  local res = { watch = listWatch }
  if (listWatch.value.len() == 0)
    return res
  return res.__update({
    margin = [0, 0, smallPadding, 0]
    children = note(::loc("squad/unableAddSoldier"))
  })
}

local bg = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  padding = bigPadding
  flow = FLOW_VERTICAL
}

local faBtnParams = {
  borderWidth = 0
  borderRadius = 0
}
local faBtnVisualDisabled = faBtnParams.__merge({
  style = {
    BgNormal = Color(20, 20, 20, 170)
    BdNormal = Color(20, 20, 20, 20)
    TextNormal = Color(0, 0, 0, 100)
  }
})

local function manageBlock() {
  local { canUp, canDown, canTake, canRemove, takeAvailable } = moveParams.value
  return {
    watch = moveParams
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    halign = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      FAButton("arrow-up", @() moveCurSoldier(-1), faBtnParams.__merge({
        key = $"moveUp_{canUp}"
        isEnabled = canUp
        hotkeys = canUp ? [["^J:Y", { description = ::loc("Move Up") }]] : null
      })),
      FAButton("arrow-down", @() moveCurSoldier(1), faBtnParams.__merge({
        key = $"moveDown_{canDown}"
        isEnabled = canDown
        hotkeys = canDown ? [["^J:X", { description = ::loc("Move Down") }]] : null
      })),
      canTake
        ? FAButton("arrow-left", curSoldierToSquad,
            (takeAvailable ? faBtnParams : faBtnVisualDisabled).__merge({
              key = $"moveToSquad_{takeAvailable}"
              hotkeys = [["^J:LB", { description = ::loc("TakeToBattle") }]]
            }))
        : FAButton("arrow-right", curSoldierToReserve, faBtnParams.__merge({
            key = $"moveToReserve_{canRemove}"
            isEnabled = canRemove
            hotkeys = canRemove ? [["^J:RB", { description = ::loc("MoveToReserve") }]] : null
          })),
      { size = flex() },
      buttonOk
    ]
  }
}

local soldiersManageHint = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    noteTextArea(::loc("soldier/manageHeader"))
    noteTextArea(::loc("soldier/maxSoldiers"))
  ]
}

local gapBlock = { size = [flex(), bigPadding] }

local hasEmptySlotsBlink = ::Computed(function() {
  return reserveSoldiers.value.slice(0, reserveAvailableSize.value)
    .findindex(@(s) unseenSoldiers.value?[s.guid] ?? false) != null
})

local squadList = bg.__merge({
  size = [slotWithPadding[0] + 2 * bigPadding, SIZE_TO_CONTENT]
  children = [
    squadHeader({
      curSquad = soldiersSquad
      curSquadParams = soldiersSquadParams
      soldiersList = ::Computed(@() squadSoldiers.value.filter(@(s) s != null))
      soldiersStatuses = soldiersStatuses
      vehicleCapacity = ::Watched(0)
    })
    note(::loc("menu/soldier"))
    mkSoldiersList(squadSoldiers, false, ::Watched(0), slotsHighlight, hasEmptySlotsBlink)
    soldiersManageHint
    gapBlock
    manageBlock
  ]
})

local getSoldiersBlock = {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    noteTextArea({
      text = ::loc("squad/getMoreSoldiers")
      font = Fonts.small_text
    }).__update({halign = ALIGN_CENTER})
    Flat(::loc("menu/enlistedShop"), function() {
      closeChooseSoldiersWnd()
      setCurSection("SHOP")
    })
  ]
}

local function reserveList() {
  if (reserveSoldiers.value.len() == 0)
    return bg.__merge({
      watch = reserveSoldiers
      size = [slotWithPadding[0] + 2 * bigPadding, flex()]
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      behavior = Behaviors.Button // only to attract cursor on dirpad navigation
      children = getSoldiersBlock
    })

  local availList = ::Computed(@() reserveSoldiers.value.slice(0, reserveAvailableSize.value))
  local blockedList = ::Computed(@() reserveSoldiers.value.slice(reserveAvailableSize.value))
  return bg.__merge({
    watch = [ reserveSoldiers curArmyReserveCapacity ]
    size = [slotWithPadding[0] + 2 * bigPadding, flex()]
    children = [
      reserveCountBlock
      makeVertScroll({
        xmbNode = ::XmbContainer({
          canFocus = @() false
          scrollSpeed = 5.0
        })
        flow = FLOW_VERTICAL
        children = [
          mkSoldiersList(availList, true, maxSoldiersInBattle)
          labelUnableToAdd(blockedList)
          mkSoldiersList(blockedList, false, ::Computed(@() maxSoldiersInBattle.value + reserveAvailableSize.value))
          reserveSoldiers.value.len() < curArmyReserveCapacity.value ? getSoldiersBlock : null
        ]
      }, scrollbarParams)
    ]
  })
}

local function mkDismissBtn(soldier) {
  if (soldier == null || getLinkedSquadGuid(soldier) != null)
    return null

  return function() {
    local res = {
      watch = [curArmyReserve, curArmyReserveCapacity, isDismissInProgress]
    }
    local reserveCur = (curArmyReserve.value ?? []).len()
    local reserveMax = curArmyReserveCapacity.value ?? 0
    if (reserveMax <= 0 || (1.0 / reserveMax * reserveCur) < 0.1)
      return res

    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      children = [
        isDismissInProgress.value
          ? spinner
          : SmallFlat(::loc("btn/removeSoldier"),
              function() {
                msgbox.show({
                  text = ::loc("msg/removeSoldierConfirm")
                  buttons = [
                    {
                      text = ::loc("Yes")
                      action = function() {
                        dismissSoldier(getLinkedArmyName(soldier), soldier.guid)
                      }
                      isCurrent = true
                    }
                    {
                      text = ::loc("Cancel"), isCancel = true
                    }
                  ]
                })
              },
              { margin = 0, padding = [bigPadding, 2 * bigPadding] })
      ]
    })
  }
}

local soldiersContent = {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    squadList
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      behavior = Behaviors.DragAndDrop
      onDrop = @(data) soldierToReserveByIdx(data?.soldierIdx)
      canDrop = @(data) data?.soldierIdx != null && data.soldierIdx < maxSoldiersInBattle.value
      skipDirPadNav = true
      children = [
        reserveList
        mkSoldierInfo({
          soldierInfoWatch = selectedSoldier
          mkDismissBtn = mkDismissBtn
        })
      ]
    }
  ]
}

local function chooseSoldiersScene() {
  local borders = safeAreaBorders.value
  return {
    watch = [safeAreaBorders, curArmy]
    size = [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    padding = [borders[0], 0, 0, 0]

    children = [
      mkHeader({
        armyId = curArmy.value
        textLocId = "soldier/manageTitle"
        closeButton = closeBtnBase({ onClick = applyAndClose })
      })
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [0, borders[1], borders[2], borders[3]]
        children = soldiersContent
      }
    ]
  }
}

local isOpened = keepref(::Computed(@() soldiersSquad.value != null))
local open = @() sceneWithCameraAdd(chooseSoldiersScene, "soldiers")
if (isOpened.value)
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSoldiersScene)
})
 