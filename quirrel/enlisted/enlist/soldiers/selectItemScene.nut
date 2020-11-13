local unseenSignal = require("enlist/components/unseenSignal.nut")
local { markSeenUpdates, curUnseenAvailableUpgrades } = require("model/unseenUpgrades.nut")
local {
  defTxtColor, textBgBlurColor, activeTxtColor, blurBgColor, blockedBgColor,
  blurBgFillColor, unitSize, bigPadding, smallPadding
} = require("enlisted/enlist/viewConst.nut")
local { show, showMessageWithContent } = require("enlist/components/msgbox.nut")
local { safeAreaBorders } = require("enlist/options/safeAreaState.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local textButton = require("enlist/components/textButton.nut")
local { makeVertScroll } = require("daRg/components/scrollbar.nut")
local { statusIconCtor } = require("components/itemPkg.nut")
local { mkItemDemands, mkItemListDemands } = require("model/mkItemDemands.nut")
local { sceneWithCameraAdd, sceneWithCameraRemove } = require("enlisted/enlist/sceneWithCamera.nut")
local { itemTypesInSlots } = require("model/all_items_templates.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")
local itemDetailsComp = require("components/itemDetailsComp.nut")
local { tooltip, normalTooltipTop } = require("ui/style/cursors.nut")
local spinner = require("enlist/components/spinner.nut")({
  height = ::hdpx(50)
  margin = [0, bigPadding, 0, 0]
})
local mkHeader = require("enlisted/enlist/components/mkHeader.nut")
local mkToggleHeader = require("enlisted/enlist/components/mkToggleHeader.nut")

local { txt } = require("enlisted/enlist/components/defcomps.nut")
local mkItemWithMods = require("mkItemWithMods.nut")
local mkSoldierInfo = require("mkSoldierInfo.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")
local itemsModifyConfig = require("enlisted/enlist/soldiers/model/config/itemsModifyConfig.nut")
local {
  getSoldierItemSlots, getEquippedItemGuid, maxCampaignLevel, curCampItems
} = require("enlisted/enlist/soldiers/model/state.nut")
local { isItemActionInProgress } = require("model/itemActions.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { curHoveredItem } = require("enlisted/enlist/showState.nut")
local {
  focusResearch, findResearchSlotUnlock, findResearchWeaponUnlock, findResearchUpgradeUnlock
} = require("enlisted/enlist/researches/researchesFocus.nut")
local armyEffects = require("model/armyEffects.nut")
local { unequipItem, unequipBySlot } = require("enlisted/enlist/soldiers/unequipItem.nut")
local {
  slotItems, otherSlotItems, prevItems, selectParams, curEquippedItem,
  viewItem, viewItemParts, viewSoldierInfo, paramsForPrevItems,
  openSelectItem, trySelectNext, curInventoryItem, checkSelectItem, selectItem, close,
  selectNextSlot, selectPreviousSlot, unseenViewSlotTpls, getModifyItemGuid
} = require("model/selectItemState.nut")
local { markWeaponrySeen } = require("model/unseenWeaponry.nut")
local hoverHoldAction = require("utils/hoverHoldAction.nut")
local {
  openDisassembleItemMsg, openUpgradeItemMsg, itemPartsAmountCtor
} = require("components/modifyItemComp.nut")
local { forceScrollToLevel } = require("model/armyUnlocksState.nut")
local mkItemUpgradeData = require("model/mkItemUpgradeData.nut")

const MODIFY_ITEM_REQ_LVL = 3

local getItemSelectKey = @(item) item?.isShopItem ? item?.basetpl : item?.guid

local selectedKey = Watched(null)
viewItem.subscribe(function(item) { selectedKey(getItemSelectKey(item)) })

local selectedSlot = ::Computed(function() {
  local { ownerGuid = "", slotType = "", slotId = "" } = selectParams.value
  local guid
  if (ownerGuid != "" && slotType != "")
    guid = getEquippedItemGuid(curCampItems.value, ownerGuid, slotType, slotId)
  return guid ?? "_".concat(ownerGuid, slotType, slotId)
})

local defStatusCtor = function(item, soldierWatch) {
  local demandsWatch = mkItemDemands(item, soldierWatch.value?.sClass)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.value)
  }
}

local activeItemParams = {
  statusCtor = defStatusCtor
}

local blockedItemParams = {
  bgColor = blockedBgColor
  statusCtor = defStatusCtor
  canEquip = false
  onDoubleClickCb = null
}

local prevItemParams = {
  statusCtor = defStatusCtor
  selectedKey = selectedSlot
  onClickCb = function(data) {
    local prev = paramsForPrevItems.value
    local { soldierGuid = "" } = data
    if (soldierGuid != "") //data.item is item mod
      openSelectItem({
        armyId = prev?.armyId
        ownerGuid = soldierGuid
        slotType = data.slotType
        slotId = data.slotId
      })
    else
      curInventoryItem(data.item)
  }
  canEquip = false
  onDoubleClickCb = unequipItem
}

local mkStdCtorData = @(size) {
  size = size
  itemsInRow = 1
  ctor = @(item, override) mkItemWithMods({
    isXmb = true
    item = item
    itemSize = size
    canDrag = item?.basetpl != null && (item?.count ?? 0) > 0 && (override?.canEquip ?? true)
    selectedKey = selectedKey
    selectKey = getItemSelectKey(item)
    onClickCb = @(data) data.item == item ? curInventoryItem(item)
      : (item?.guid ?? "") != "" ? openSelectItem({ // data.item is mod of item
          armyId = selectParams.value?.armyId
          ownerGuid = item.guid
          slotType = data.slotType
          slotId = data.slotId
        })
      : null
    onDoubleClickCb = function(data) {
      if (data.item != item)
        return
      selectItem(item)
      trySelectNext()
    }
  }.__update(override))
}

local defaultCtorData = mkStdCtorData([3.0 * unitSize, 2.0 * unitSize]).__update({ itemsInRow = 2 })
local mainWeaponCtorData = mkStdCtorData([7.0 * unitSize, 2.0 * unitSize])

local itemTypeCtorData = ::Computed(@() itemTypesInSlots.value.mainWeapon.map(@(v) mainWeaponCtorData))

local mkItemsList = @(listWatch, itemParamsOverride) function() {
  itemParamsOverride.soldierGuid <- viewSoldierInfo.value?.guid
  local items = listWatch.value
  local typeCtorData = itemTypeCtorData.value
  local ctorData = typeCtorData?[items?[0].itemtype] ?? defaultCtorData
  local { size, itemsInRow } = ctorData
  local itemContainerWidth = itemsInRow * size[0] + (itemsInRow - 1) * bigPadding
  return wrap(
    items.map(@(item) (typeCtorData?[item?.itemtype] ?? ctorData).ctor(item, itemParamsOverride)),
    { width = itemContainerWidth, hGap = smallPadding, vGap = smallPadding, hplace = ALIGN_CENTER }
  ).__update({ watch = [listWatch, itemTypeCtorData, viewSoldierInfo] })
}

local sortDemandsOrder = @(d) d?.canObtainInShop == true ? 2000
  : d?.classLimit != null ? 1500
  : "levelLimit" in d ? 1000 - d.levelLimit
  : 0

local function sortByDemands(a, b) {
  return (b == "") <=> (a == "")
    || sortDemandsOrder(b) <=> sortDemandsOrder(a)
}

local function mkDemandHeader(demand) {
  local key = demand.keys()?[0]
  local value = demand?[key]
  local suffix = value == true ? "_yes"
    : value == false ? "_no"
    : ""
  return {
    rendObj = ROBJ_DTEXT
    size = [flex(), SIZE_TO_CONTENT]
    margin = [smallPadding, 0, 0, 0]
    text = ::loc($"itemDemandsHeader/{key}{suffix}", demand)
    font = Fonts.small_text
    color = defTxtColor
  }
}

local mkItemsGroupedList = @(listWatch, itemParamsOverride) function() {
  itemParamsOverride.soldierGuid <- viewSoldierInfo.value?.guid
  local itemsWithDemands = mkItemListDemands(listWatch.value, viewSoldierInfo.value?.sClass)
  local itemsDemands = itemsWithDemands.value
  local typeCtorData = itemTypeCtorData.value
  local ctorData = typeCtorData?[itemsDemands?[0].item.itemtype] ?? defaultCtorData
  local { size, itemsInRow } = ctorData
  local itemContainerWidth = itemsInRow * size[0] + (itemsInRow - 1) * bigPadding

  local groupedItems = {}
  foreach (data in itemsDemands) {
    local { item, demands = "" } = data
    groupedItems[demands] <- (groupedItems?[demands] ?? []).append(item)
  }
  local children = []
  local demandsOrdered = groupedItems.keys().sort(sortByDemands)
  foreach (demand in demandsOrdered) {
    if (demand != "")
      children.append(mkDemandHeader(demand))

    local itemsList = groupedItems[demand].map(function(item) {
        local ctor = (typeCtorData?[item?.itemtype] ?? ctorData).ctor
        local { basetpl = "" } = item
        local isUnseen = ::Computed(@() basetpl in unseenViewSlotTpls.value
          || basetpl in curUnseenAvailableUpgrades.value)
        return ctor(item,
          itemParamsOverride.__merge({
            hasUnseenSign = isUnseen
            onHoverCb = hoverHoldAction("unseenSoldierItem", basetpl,
              function(tpl) {
                local { armyId = null } = selectParams.value
                if (isUnseen.value && armyId != null)
                  markWeaponrySeen(armyId, tpl)
              })
          }))
      })

    children.append(wrap(itemsList, {
      width = itemContainerWidth, hGap = smallPadding, vGap = smallPadding, hplace = ALIGN_CENTER
    }))
  }
  return {
    watch = [listWatch, itemTypeCtorData, viewSoldierInfo, itemsWithDemands]
    size = [itemContainerWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = children
  }
}

local armoryList = mkItemsGroupedList(slotItems, activeItemParams)
local otherList = mkItemsGroupedList(otherSlotItems, blockedItemParams)
local prevArmory = mkItemsList(prevItems, prevItemParams)

local backButton = textButton.Flat(::loc("mainmenu/btnBack"), @() close(),
  { margin = [0, bigPadding, 0, 0] })

local mkChooseButton = @(curItem, selItem)
  selItem == curItem || (selItem == null && curItem?.basetpl == null) || checkSelectItem(curItem) != null
    ? null
    : textButton.PrimaryFlat(::loc("mainmenu/btnSelect"), @() selectItem(curItem),
        { margin = [0, bigPadding, 0, 0] })

local openObtainItemMsgbox = ::kwarg(function (item, text, btnLocId, cb) {
  showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      gap = sh(3)
      halign = ALIGN_CENTER
      children = [
        txt({
          text = text
          font = Fonts.medium_text
        })
        mkItemWithMods({
          item = item
          itemSize = [7.0 * unitSize, 2.0 * unitSize]
          isInteractive = false
        })
        {
          size = [flex(), sh(3)]
        }
      ]
    }
    buttons = [
      {
        text = ::loc(btnLocId)
        action = cb
        isCurrent = true
      }
      { text = ::loc("OK"), isCancel = true }
    ]
  })
})

local function mkObtainButton(item, soldier) {
  local demands = mkItemDemands(item, soldier?.sClass).value
  local { classLimit = null, levelLimit = null, canObtainInShop = false } = demands
  return demands == null ? null
    : classLimit != null ? textButton.Flat(::loc("mainmenu/btnResearch"),
        @() openObtainItemMsgbox({
          item = item
          text = ::loc("itemClassResearch", { soldierClass = ::loc(soldierClasses?[classLimit].locId ?? "unknown") })
          btnLocId = "GoToResearch"
          cb = function() {
            close()
            focusResearch(findResearchWeaponUnlock(item, soldier))
          }
        }),
        { margin = [0, bigPadding, 0, 0] })
    : levelLimit != null ? textButton.Flat(::loc("GoToArmyLeveling"),
        function() {
          forceScrollToLevel(levelLimit)
          close()
          setCurSection("SQUADS")
        },
        { margin = [0, bigPadding, 0, 0] })
    : canObtainInShop ? textButton.Flat(::loc("GoToShop"),
        function() {
          close()
          setCurSection("SHOP")
        },
        { margin = [0, bigPadding, 0, 0] })
    : null
}

local mkListToggleHeader = @(sClass, flag) mkToggleHeader(flag
  ::loc("Not available for class", { soldierClass = ::loc(soldierClasses?[sClass].locId ?? "unknown") }))

local function otherItemsBlock() {
  local res = { watch = [viewSoldierInfo, otherSlotItems] }
  if (otherSlotItems.value.len() == 0)
    return res

  local isListExpanded = Watched(false)
  local sClass = viewSoldierInfo.value?.sClass ?? "unknown"
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkListToggleHeader(sClass, isListExpanded)
      @() {
        watch = isListExpanded
        children = isListExpanded.value ? otherList : null
      }
    ]
  })
}

local mkItemsListBlock = @(children) {
  size = [SIZE_TO_CONTENT, flex()]
  padding = [bigPadding, bigPadding]
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  xmbNode = ::XmbContainer({
    canFocus = @() false
    scrollSpeed = 5.0
    isViewport = true
  })
  children = makeVertScroll(children, {
    size = [SIZE_TO_CONTENT, flex()]
    needReservePlace = false
  })
  canDrop = @(data) data?.slotType != null
  onDrop = @(data) unequipItem(data)
}

local itemsListBlock = @() {
  size = [SIZE_TO_CONTENT, flex()]
  watch = [slotItems, otherSlotItems]
  children = slotItems.value.len() > 0 || otherSlotItems.value.len() > 0
    ? mkItemsListBlock({
        flow = FLOW_VERTICAL
        children = [
          armoryList
          otherItemsBlock
        ]
      })
    : null
}

local prevItemsListBlock = @() {
  size = [SIZE_TO_CONTENT, flex()]
  watch = prevItems
  children = prevItems.value.len()
    ? mkItemsListBlock(prevArmory)
    : null
}

local canModifyItems = ::Computed(@() maxCampaignLevel.value >= MODIFY_ITEM_REQ_LVL)

local canDisassembly = @(item)
   (item?.guid ?? "") != "" && (item?.disassembly ?? "").len() > 0

local mkDisassemblyBtn = @(item) function() {
  local res = {
    watch = [canModifyItems, itemsModifyConfig, selectParams, armyEffects]
  }

  local iGuid = getModifyItemGuid(item)
  if (!canDisassembly(item) || !canModifyItems.value || iGuid == null)
    return res

  local modifyData = itemsModifyConfig.value?[item?.tier ?? 0]
  if (modifyData == null)
    return res

  local disassembleMin = modifyData?.disassembleMin ?? 0
  local disassembleMax = modifyData?.disassembleMax ?? 0
  if (disassembleMin <= 0 && disassembleMax <= 0)
    return res

  local armyId = selectParams.value?.armyId
  local bonus = ((armyEffects.value?[armyId].disassemble_bonus ?? {})?[item?.basetpl] ?? 0.0) + 1.0
  local minCount = (disassembleMin * bonus).tointeger()
  local maxCount = (disassembleMax * bonus).tointeger()
  local mkResultObj = itemPartsAmountCtor(minCount, maxCount)
  return res.__update({
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    margin = [0, bigPadding, 0, 0]
    children = [
      bonus == 1.0 ? null : txt({
        text = ::loc("disassembleBonus", { bonus = (bonus * 100 - 100).tointeger() })
        color = activeTxtColor
      })
      textButton.Flat(::loc("btn/disassemble"),
        function() {
          openDisassembleItemMsg(item, iGuid, armyId, mkResultObj)
        }, {
          margin = 0
          textCtor = mkResultObj
          cursor = normalTooltipTop
          onHover = @(on) tooltip.state(on ? ::loc("tip/btnDisassemble") : null)
        })
    ]
  })
}

local openResearchUpgradeMsgbox = function(item, armyId) {
  local research = findResearchUpgradeUnlock(armyId, item)
  if (research == null)
    show({
      text = ::loc("itemUpgradeNoSquad")
      buttons = [
        {
          text = ::loc("squads/gotoUnlockBtn")
          action = function() {
            close()
            setCurSection("SQUADS")
          }
          isCurrent = true
        }
        { text = ::loc("OK"), isCancel = true }
      ]
    })
  else
    show({
      text = ::loc("itemUpgradeResearch")
      buttons = [
        {
          text = ::loc("mainmenu/btnResearch")
          action = function() {
            close()
            focusResearch(research)
          }
          isCurrent = true
        }
        { text = ::loc("OK"), isCancel = true }
      ]
    })
}

local mkUpgradeBtn = function(item) {
  local upgradeDataWatch = mkItemUpgradeData(item)
  return function() {
    local res = {
      watch = [upgradeDataWatch, curUnseenAvailableUpgrades]
    }

    local upgradeData = upgradeDataWatch.value

    if (!upgradeData.isUpgradable)
      return res

    res.margin <- [0, bigPadding, 0, 0]
    local { isResearchRequired, armyId, hasEnoughParts, partsRequired,
      modifyData, upgradeMult, iGuid, itemBaseTpl } = upgradeData

    if (isResearchRequired)
      return res.__update({
        children = textButton.Flat(::loc("btn/upgrade"), @() openResearchUpgradeMsgbox(item, armyId), {
          margin = 0
          cursor = normalTooltipTop
          onHover = @(on) tooltip.state(on ? ::loc("tip/btnUpgrade") : null)
        })
      })

    local bCtor = hasEnoughParts ? textButton.Purchase : textButton.Flat
    local mkSacrificeObj = itemPartsAmountCtor(partsRequired)

    return res.__update({
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = [
            txt({
              text = ::loc("upgradeChance", { chance = (modifyData.upgradeChance * 100).tointeger() })
              color = activeTxtColor
            })
            upgradeMult == 1.0 ? null : txt({
              text = ::loc("upgradeDiscount", { discount = (100 - upgradeMult * 100).tointeger() })
              color = activeTxtColor
            })
          ]
        }
        {
          children = [
            bCtor(::loc("btn/upgrade"),
              @() openUpgradeItemMsg(item, iGuid, armyId, modifyData, mkSacrificeObj), {
                margin = 0
                textCtor = mkSacrificeObj
                cursor = normalTooltipTop
                onHover = function(on) {
                  if (item?.basetpl in curUnseenAvailableUpgrades.value)
                    hoverHoldAction("unseenUpdate", itemBaseTpl,
                      @(tpl) markSeenUpdates(selectParams.value?.armyId, [tpl]))(on)
                  tooltip.state(on ? ::loc("tip/btnUpgrade") : null)
                }
              })
            item?.basetpl in curUnseenAvailableUpgrades.value
              ? unseenSignal(0.8).__update({ hplace = ALIGN_RIGHT })
              : null
          ]
        }
      ]
    })
  }
}

local isModifiable = @(item)
  (item?.disassembly ?? "").len() > 0

local buttons = @() {
  watch = [viewItem, curEquippedItem, viewItemParts, viewSoldierInfo, isItemActionInProgress, canModifyItems, isGamepad]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    isModifiable(viewItem.value) && canModifyItems.value ? itemDetailsComp.mkModifyInfo(viewItemParts.value) : null
    {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = textBgBlurColor
      flow = FLOW_HORIZONTAL
      padding = [bigPadding, 0, bigPadding, bigPadding]
      valign = ALIGN_BOTTOM
      children = [ !isGamepad.value ? backButton : null]
        .extend(isItemActionInProgress.value
          ? [spinner]
          : [
              mkObtainButton(viewItem.value, viewSoldierInfo.value)
              mkDisassemblyBtn(viewItem.value)
              mkUpgradeBtn(viewItem.value)
              mkChooseButton(viewItem.value, curEquippedItem.value)
            ])
    }
  ]
}

local infoBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_VERTICAL
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  gap = bigPadding
  children = [
    itemDetailsComp.mkItemDetails(viewItem, viewSoldierInfo)
    buttons
  ]
}

local animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[-hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[0, 0], playFadeOut = true, to = [-hdpx(150), 0], duration = 0.2, easing = OutQuad }
]

local function getItemSlot(item, soldier) {
  if (!item || !soldier)
    return null
  local ownerGuid = soldier.guid
  local itemSlot = getSoldierItemSlots(ownerGuid)
    .findvalue(@(slot) slot.item?.guid == item?.guid)
  if (!itemSlot)
    return null
  local { slotType, slotId } = itemSlot
  if (slotId == null) {
    local equipScheme = soldier?.equipScheme ?? {}
    slotId = slotType
    slotType = equipScheme.findindex(@(val) slotType in val)
    if (slotType == null)
      return null
  }
  return {
    ownerGuid = ownerGuid
    slotType = slotType
    slotId = slotId
  }
}

local quickEquipHotkeys = function() {
  local item = curHoveredItem.value
  local res = { watch = [isGamepad, curHoveredItem] }
  if (!isGamepad.value || item == null)
    return res

  local soldier = viewSoldierInfo.value
  local slot = getItemSlot(item, soldier)
  return slot != null
    // quick uneqip
    ? res.__update({
        children = {
          key = $"unequip_{item?.guid}"
          hotkeys = [["^J:Y", {
            description = ::loc("equip/quickUnequip")
            action = function() {
              unequipBySlot(slot)
              openSelectItem(slot.__merge({ armyId = selectParams.value?.armyId }))
            }
          }]]
        }
      })
    // quick equip
    : res.__update({
        children = {
          key = $"equip_{item?.guid}"
          hotkeys = [["^J:Y", {
            description = ::loc("equip/quickEquip")
            action = function() {
              selectItem(item)
            }
          }]]
        }
      })
}

local function gotoSlotResearchUnlock(soldier, slotType, slotId) {
  close()
  focusResearch(findResearchSlotUnlock(soldier, slotType, slotId))
}

local itemsContent = [
  {
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    animations = animations
    transform = {}
    children = [
      mkSoldierInfo({
        soldierInfoWatch = viewSoldierInfo
        isMoveRight = false
        selectedKeyWatch = selectedSlot
        onDoubleClickCb = unequipItem
        onResearchClickCb = gotoSlotResearchUnlock
      })
      prevItemsListBlock
      itemsListBlock
      {
        size = flex()
        halign = ALIGN_RIGHT
        children = infoBlock
        behavior = [Behaviors.DragAndDrop]
        onDrop = @(data) unequipItem(data)
        canDrop = @(data) data?.slotType != null
        skipDirPadNav = true
      }
    ]
    hotkeys = [
      ["^Tab | J:RB", { action = selectNextSlot, description = ::loc("equip/nextSlot") }],
      ["^L.Shift Tab | R.Shift Tab | J:LB", { action = selectPreviousSlot, description = ::loc("equip/prevSlot") }]
    ]
  }
  quickEquipHotkeys
]

local function selectItemScene() {
  local borders = safeAreaBorders.value
  return {
    watch = [safeAreaBorders]
    size = [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    padding = [borders[0], 0, 0, 0]
    children = [
      @() {
        size = [flex(), SIZE_TO_CONTENT]
        watch = selectParams
        children = mkHeader({
          armyId = selectParams.value?.armyId
          textLocId = "Choose item"
          closeButton = closeBtnBase({ onClick = close })
        })
      }
      {
        size = flex()
        flow = FLOW_VERTICAL
        padding = [0, borders[1], borders[2], borders[3]]
        children = itemsContent
      }
    ]
  }
}

local function open() {
  sceneWithCameraAdd(selectItemScene, "armory")
}

if (selectParams.value)
  open()

selectParams.subscribe(function(p) {
  if (p == null)
    sceneWithCameraRemove(selectItemScene)
  else
    open()
})
 