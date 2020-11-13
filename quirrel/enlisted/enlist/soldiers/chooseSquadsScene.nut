local textButton = require("enlist/components/textButton.nut")
local viewConst = require("enlisted/enlist/viewConst.nut")
local mkHeader = require("enlisted/enlist/components/mkHeader.nut")
local msgbox = require("enlist/components/msgbox.nut")
local { note, txt, noteTextArea } = require("enlisted/enlist/components/defcomps.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { mkHorizontalSlot, mkEmptyHorizontalSlot } = require("mkSquadsList.nut")
local { unseenSquads, markSeenSquads } = require("model/unseenSquads.nut")
local unseenSignal = require("enlist/components/unseenSignal.nut")()
local hoverHoldAction = require("utils/hoverHoldAction.nut")
local buyShopItem = require("enlisted/enlist/shop/buyShopItem.nut")
local currenciesWidgetUi = require("enlisted/enlist/currency/currenciesWidgetUi.nut")
local { squadsArmy, selectedSquadId, chosenSquads, reserveSquads,
  applyAndClose, closeAndOpenCampaign, changeSquadOrderByUnlockedIdx,
  squadsArmyLimits, moveIndex, changeList, curArmyLockedSquadsData
} = require("model/chooseSquadsState.nut")
local {
  viewSquadId, forceScrollToLevel, curArmySquadsUnlocks
} = require("model/armyUnlocksState.nut")
local { makeVertScroll, thinStyle } = require("ui/components/scrollbar.nut")
local { allArmiesInfo } = require("enlisted/enlist/soldiers/model/config/gameProfile.nut")
local { hasPremium } = require("enlisted/enlist/currency/premium.nut")
local { shopItems, isAvailableByLimit } = require("enlisted/enlist/shop/armyShopState.nut")
local { promoSmall } = require("enlisted/enlist/currency/pkgPremiumWidgets.nut")
local { byId } = require("enlist/currency/currencies.nut")
local { currencyBtn } = require("enlisted/enlist/currency/currenciesComp.nut")
local { bonusesList, curBonuses } = require("enlisted/enlist/currency/bonuses.nut")
local { purchasesCount } = require("enlisted/enlist/meta/profile.nut")

local curArmyUnseenSquads = ::Computed(@() unseenSquads.value?[squadsArmy.value])
local borders = safeAreaBorders.value

local function moveSquad(direction) {
  local squadId = selectedSquadId.value
  if (squadId == null)
    return
  foreach(watch in [chosenSquads, reserveSquads]) {
    local list = watch.value
    local idx = list.findindex(@(s) s?.squadId == squadId)
    if (idx == null)
      continue
    local newIdx = idx + direction
    if (newIdx in list) {
      watch(moveIndex(list, idx, newIdx))
      markSeenSquads(squadsArmy.value, [squadId])
    }
    break
  }
}

local moveParams = ::Computed(function() {
  local watch = null
  local idx = null
  local selId = selectedSquadId.value
  if (selId != null)
    foreach(w in [chosenSquads, reserveSquads]) {
      idx = w.value.findindex(@(s) s?.squadId == selId)
      if (idx != null) {
        watch = w
        break
      }
    }
  return {
    canUp = watch != null && idx > 0
    canDown = watch != null && idx < watch.value.len() - 1
    canTake = watch == reserveSquads
    canRemove = watch == chosenSquads
  }
})

local buttonOk = textButton.PrimaryFlat(::loc("Ok"), applyAndClose, { margin = 0 })

local sellingBonusData = ::Computed(function() {
  if (!hasPremium.value)
    return null

  local bonusId = bonusesList.value.findindex(@(bonus, id)
    !(id in curBonuses.value)
    && (bonus.effects?.maxSquadsInBattle != null
      || bonus.effects?.maxInfantrySquads != null
      || bonus.effects?.maxVehicleSquads != null))
  if (bonusId == null)
    return null

  local res = shopItems.value.findvalue(@(shopItem)
    (shopItem?.bonusId ?? "") == bonusId)
  return isAvailableByLimit(res, purchasesCount.value) ? res : null
})

local mkBonusButton = @(bonusData) function () {
  if (bonusData == null)
    return null

  local currency = byId.value?[bonusData.curShopItemPrice.currencyId]
  if (currency == null)
    return null

  local price = bonusData.curShopItemPrice.price
  return {
    watch = byId
    size = [flex(), SIZE_TO_CONTENT]
    children = currencyBtn({
      btnText = ::loc(::loc("btn/buyCustom", { item = ::loc(bonusData.nameLocId) }))
      currency = currency
      price = price
      style = {
        size = [flex(), SIZE_TO_CONTENT]
        margin = 0
      }
      cb = @() buyShopItem(shopItems.value?[bonusData.guid])
    })
  }
}

local upgradeBlock = @(){
  watch = [sellingBonusData, monetization]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  margin = [viewConst.bigPadding,0,0,0]
  children = monetization.value
    ? [
        promoSmall("premium/buyForSquads", {
          rendObj = ROBJ_SOLID
          color = viewConst.defBgColor
          padding = viewConst.bigPadding
        }, null, "manage_squads")
        mkBonusButton(sellingBonusData.value)
      ]
    : null
}

local squadManageHint = @() {
  watch = squadsArmyLimits
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  padding = [viewConst.smallPadding, 0, 0, 0]
  children = [
    note(::loc("squads/manageHeader"))
    note(::loc("squads/maxSquadsHint", { amount = squadsArmyLimits.value.maxSquadsInBattle }))
    noteTextArea(::loc("squads/maxSquadsByTypeHint",
      { infantry = squadsArmyLimits.value.maxInfantrySquads, vehicle = squadsArmyLimits.value.maxVehicleSquads }))
  ]
}

local faBtnParams = {
  borderWidth = 0
  borderRadius = 0
}

local function manageBlock() {
  local { canUp, canDown, canTake, canRemove } = moveParams.value
  return {
    watch = moveParams
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = viewConst.bigPadding
    children = [
      textButton.FAButton("arrow-up", @() moveSquad(-1),
        faBtnParams.__merge({
          isEnabled = canUp
          hotkeys = [["^J:Y", {description = ::loc("Move Up")}]]
        })),
      textButton.FAButton("arrow-down", @() moveSquad(1),
        faBtnParams.__merge({
          isEnabled = canDown
          hotkeys = [["^J:X", {description = ::loc("Move Down")}]]
        })),
      canTake ? textButton.FAButton("arrow-left", changeList,
            faBtnParams.__merge({
              isEnabled = canTake
              hotkeys = [["^J:LB", {description = ::loc("TakeToBattle")}]]
            }))
        : canRemove ? textButton.FAButton("arrow-right", changeList,
            faBtnParams.__merge({
              isEnabled = canRemove
              hotkeys = [["^J:RB", {description = ::loc("MoveToReserve")}]]
            }))
        : null,
      { size = [flex(), 0] },
      buttonOk,
    ]
  }
}

local blocksGap = { size = [0, viewConst.bigPadding] }

local squadUnseenMark = @(squadId) @() {
  watch = curArmyUnseenSquads
  hplace = ALIGN_RIGHT
  children = (curArmyUnseenSquads.value?[squadId] ?? false) ? unseenSignal : null
}

local mkSquadSlot = @(squad, idx, slotsCount, isReserveEmpty = true) {
  children = squad != null
    ? [
        mkHorizontalSlot(
          squad.__merge({
            idx = idx
            onDropCb = changeSquadOrderByUnlockedIdx
            onInfoCb = @(squadId) viewSquadId(squadId)
            onClick = @() selectedSquadId(squad.squadId)
            isSelected = ::Computed(@() selectedSquadId.value == squad.squadId)
            override = {
              onHover = hoverHoldAction("unseenSquad", squad.squadId,
                @(squadId) markSeenSquads(squadsArmy.value, [squadId]))
            }
            group = ::ElemGroup()
            fixedSlots = slotsCount
          }))
        squadUnseenMark(squad.squadId)
      ]
    : mkEmptyHorizontalSlot({
        idx = idx
        onDropCb = changeSquadOrderByUnlockedIdx
        fixedSlots = slotsCount
        hasBlink = !isReserveEmpty
      })
}

local mkChosenSquads = @(chosen, ctor) {
  size = [SIZE_TO_CONTENT, viewConst.squadSlotHorSize[1] * chosen.len()]
  flow = FLOW_VERTICAL
  clipChildren = true
  children = chosen.map(ctor)
}

local panelBg = {
  size = SIZE_TO_CONTENT
  padding = viewConst.bigPadding
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = viewConst.blurBgColor
  fillColor = viewConst.blurBgFillColor
  flow = FLOW_VERTICAL
}

local leftPanel = @() panelBg.__merge({
  watch = [chosenSquads, reserveSquads]
  children = [
    txt({text=::loc("squads/battleSquads", "Battle squads"), margin=[::hdpx(5),0]})
    mkChosenSquads(chosenSquads.value, @(squad, idx)
      mkSquadSlot(squad, idx, chosenSquads.value.len(), reserveSquads.value.len() == 0))
    blocksGap
    squadManageHint
    blocksGap
    manageBlock
    upgradeBlock
  ]
})

local slotsCount = ::Computed(@() chosenSquads.value.len())

local showLockedSquadMsgbox = function(squadId, nameLocId) {
  local unlock = curArmySquadsUnlocks.value
    .findvalue(@(u) u.unlockType == "squad" && u.unlockId == squadId)
  if (unlock == null)
    return

  msgbox.show({
    text = ::loc("squads/cantUseLocked", {
      name = ::loc(nameLocId)
      level = unlock.level
    })
    buttons = [
      { text = ::loc("OK"), isCancel = true }
      {
        text = ::loc("squads/gotoUnlockBtn")
        action = function() {
          forceScrollToLevel(unlock.level)
          closeAndOpenCampaign()
        }
        isCurrent = true }
    ]
  })
}

local function rightPanel() {
  local res = {
    watch = [slotsCount, reserveSquads, curArmyLockedSquadsData]
  }
  local sCount = slotsCount.value
  local children = reserveSquads.value
    .map(@(squad, idx) mkSquadSlot(squad, idx + sCount, sCount))

  local lockedChildren = curArmyLockedSquadsData.value
    .map(@(val) mkHorizontalSlot(val.squad.__merge({
      isLocked = true
      idx = -1
      onClick = @() showLockedSquadMsgbox(val.squad.squadId, val.squad.nameLocId)
      unlocObj = txt({
        text = ::loc("campaignLevel", { lvl = val.unlockData.level })
        margin = viewConst.bigPadding
      })
    })))
  if (lockedChildren.len() > 0) {
    children
      .append(txt({
        text = ::loc("squads/lockedSquads", "Locked squads")
        margin = [::hdpx(5), 0]
      }))
      .extend(lockedChildren)
  }

  return panelBg.__merge(res).__update({
    size = [SIZE_TO_CONTENT, flex()]
    children = [
      txt({
        text = ::loc("squads/reserveSquads", "Reserve squads")
        margin = [::hdpx(5), 0]
      })
      makeVertScroll({
          flow = FLOW_VERTICAL
          children = children
        },
        {
          size = [SIZE_TO_CONTENT, flex()]
          styling = thinStyle
        })
    ]
  })
}

local allSquadsList = {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = viewConst.bigPadding
  children = [
    leftPanel
    rightPanel
  ]
}

local chooseSquadsScene = @() {
  watch = [squadsArmy, curArmyUnseenSquads, allArmiesInfo]
  size = [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  padding = [borders[0], 0, 0, 0]

  onDetach = @() markSeenSquads(squadsArmy.value, (curArmyUnseenSquads.value ?? {}).keys())

  children = [
    mkHeader({
      armyId = squadsArmy.value
      textLocId = "squads/manageTitle"
      closeButton = closeBtnBase({ onClick = applyAndClose })
      addToRight = @() {
        watch = monetization
        children = monetization.value ? currenciesWidgetUi : null
      }
    })
    {
      size = flex()
      padding = [0, borders[1], borders[2], borders[3]]
      children = allSquadsList
    }
  ]
}

local isOpened = keepref(::Computed(@() squadsArmy.value != null))
local open = @() sceneWithCameraAdd(chooseSquadsScene, "soldiers")
if (isOpened.value)
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSquadsScene)
}) 