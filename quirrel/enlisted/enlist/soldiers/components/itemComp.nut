local unseenSignal = require("enlist/components/unseenSignal.nut")(0.8)
local fa = require("daRg/components/fontawesome.map.nut")
local { isGamepad } = require("ui/control/active_controls.nut")
local {
  u, gap, bigGap, bigPadding, smallPadding, soldierWndWidth, fadedTxtColor, defBgColor,
  defTxtColor, blockedBgColor, listCtors
} = require("enlisted/enlist/viewConst.nut")
local listTxtColor = listCtors.txtColor
local listBgColor = listCtors.bgColor
local { statusTier, statusHintText, statusIconCtor, statusIconLocked } = require("itemPkg.nut")
local { mkItemDemands } = require("enlisted/enlist/soldiers/model/mkItemDemands.nut")
local { objInfoByGuid, getItemOwnerGuid, getSoldierItemSlots, getItemIndex,
  getDemandingSlots, getDemandingSlotsInfo, getEquippedItemGuid, curCampItems
} = require("enlisted/enlist/soldiers/model/state.nut")
local { equipItem, swapItems } = require("enlisted/enlist/soldiers/model/itemActions.nut")
local { iconByItem, getItemName, getItemDesc } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { curHoveredItem } = require("enlisted/enlist/showState.nut")
local popupsState = require("enlist/popup/popupsState.nut")
local tooltipBox = require("ui/style/tooltipBox.nut")
local soldierItemTypeIcon = require("enlisted/enlist/soldiers/components/soldierItemTypeIcon.nut")
local { FAButton } = require("enlist/components/textButton.nut")
local cursors = require("ui/style/cursors.nut")
local { unequipItem } = require("enlisted/enlist/soldiers/unequipItem.nut")
local { sound_play } = require("sound")
local mkItemUpgradeData = require("enlisted/enlist/soldiers/model/mkItemUpgradeData.nut")

local DISABLED_ITEM = { tint = ::Color(40, 40, 40, 160), picSaturate = 0.0 }

local defItemSize = [soldierWndWidth - bigPadding * 2, u * 2]

local itemDragData = Watched()

local smallMainColorText = function(text, sf, selected) {
  local res = {
    rendObj = ROBJ_DTEXT
    vplace = ALIGN_BOTTOM
    color = listTxtColor(sf, selected)
    font = Fonts.small_text
    text = text
  }
  if (!(selected || (sf & S_HOVER)))
    res.__update({
      fontFx = FFT_SHADOW
      fontFxColor = 0xFF000000
      fontFxFactor = 16
      fontFxOffsX = 1
      fontFxOffsY = 1
    })
  return res
}

local amountText = @(count, sf, selected) {
  rendObj = ROBJ_SOLID
  color = selected || (sf & S_HOVER) ? Color(120, 120, 120, 120) : Color(0, 0, 0, 120)
  size = SIZE_TO_CONTENT
  padding = [smallPadding, 2 * smallPadding]
  children = {
    rendObj = ROBJ_DTEXT
    color = listTxtColor(sf, selected)
    font = Fonts.small_text
    text = ::loc("common/amountShort", { count = count })
  }
}

local defSlotnameCtor = @(slotType, itemSize, isSelected, flags, group) slotType != null ? {
  rendObj = ROBJ_DTEXT
  group = group
  margin = smallPadding
  hplace = ALIGN_RIGHT
  color = listTxtColor(flags, isSelected)
  font = Fonts.tiny_text
  text = ::loc($"inventory/{slotType}", "")
  opacity = 0.5
} : null

local slotBlockedCtor = @(isSelected, flags, onClickCb = null) {
  size = flex()
  children = [
    statusIconLocked
    {
      rendObj = ROBJ_DTEXT
      vplace = ALIGN_BOTTOM
      padding = bigPadding
      color = listTxtColor(flags, isSelected)
      font = Fonts.tiny_text
      text = ::loc("slot/locked", "")
      opacity = 0.5
    }
    onClickCb && (flags & S_HOVER)
      ? FAButton("wrench", onClickCb, {
          hplace = ALIGN_RIGHT
          margin = bigPadding
          borderWidth = 0
          borderRadius = 0
        })
      : null
  ]
}

local nameBlockCtor = @(item, sf, selected, group) {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  padding = bigPadding
  gap = gap
  flow = FLOW_HORIZONTAL
  children = [
    soldierItemTypeIcon({
      itemType = item?.itemtype
      color = listTxtColor(sf, selected)
    })
    {
      size = [flex(), SIZE_TO_CONTENT]
      clipChildren = true
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        group = group
        behavior = Behaviors.Marquee
        scrollOnHover = true
        children = smallMainColorText(getItemName(item), sf, selected)
      }
    }
  ]
}

local function defItemCtor(item, slotType, itemSize, isSelected, flags, group) {
  local isAvailable = (item?.guid ?? "") != ""
  local isWide = (itemSize?[0] ?? 1) / (itemSize?[1] ?? 1) < 2
  local iconParams = {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    width = isWide
      ? itemSize[0] - 2 * smallPadding
      : itemSize[1] * 3 - 2 * bigPadding
    height = isWide
      ? itemSize[1] - 2 * smallPadding
      : itemSize[1] - 2 * bigPadding
  }.__update(isAvailable ? {} : DISABLED_ITEM)
  local itemName = nameBlockCtor(item, flags, isSelected, group)
  local itemIcon = iconByItem(item, iconParams)
  return {
    size = flex()
    children = [
      itemIcon
      itemName
    ]
  }
}

local defAmountCtor = @(item, sf, selected) (item?.count ?? 1) > 1
  ? amountText(item.count, sf, selected)
  : null

local mkTooltipStatus = @(item, soldierWatch) function() {
  local demandsWatch = mkItemDemands(item, soldierWatch.value?.sClass)
  local res = { watch = [demandsWatch, soldierWatch] }
  local demands = demandsWatch.value
  if (demands == null)
    return res
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    minWidth = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    margin = [bigPadding,0,0,0]
    valign = ALIGN_CENTER
    children = [
      statusHintText(demands)
      statusIconCtor(demands)
    ]
  })
}

local canEquip = @(item, scheme) item != null && !(item?.isShopItem ?? false)
  && (scheme == null
    || ((scheme?.itemTypes.len() ?? 0) == 0 && (scheme?.items.len() ?? 0) == 0)
    || scheme?.itemTypes.indexof(item?.itemtype) != null
    || scheme?.items.indexof(item?.basetpl) != null)

// targetDropData is the data of a slot, WHERE we drop an item
// draggedDropData is the data of a slot, FROM where drag originated
local function trySwapItems(toOwnerGuid, targetDropData, draggedDropData) {
  local itemGuid = null

  // dropping item from the soldier's card into storage:
  if (targetDropData.scheme == null){
    // dropping item into empty storage slot, unequip:
    if ("guid" not in targetDropData.item){
      unequipItem(draggedDropData)
      return false
    }
    // equip item from target storage slot:
    equipItem(targetDropData.item.guid, draggedDropData.slotType, draggedDropData.slotId, toOwnerGuid)
    return true
  }

  // dropping item
  local { slotId = null, slotType = null, item = {} } = targetDropData?.slotType == null ? targetDropData : draggedDropData
  local toSlotType = targetDropData?.slotType == null ? draggedDropData.slotType : targetDropData.slotType
  local toSlotId = targetDropData?.slotId == null ? draggedDropData.slotId : targetDropData.slotId
  itemGuid = item?.guid
  if (!toOwnerGuid || !itemGuid)
    return false

  local parentItemGuid = getItemOwnerGuid(itemGuid)
  if (!parentItemGuid) {
    // equip from inventory
    equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
    return true
  }

  slotId = slotId ?? getItemIndex(item)
  slotType = slotType ?? item.links[parentItemGuid]

  // swap already equipped
  local demandingSlots = getDemandingSlots(parentItemGuid, slotType)
  if (demandingSlots.len() > 0) {
    local equippedCount = demandingSlots.filter(@(v) v != null).len()
    local equippedGuid = getEquippedItemGuid(curCampItems.value, toOwnerGuid, toSlotType, toSlotId)
    if (!equippedGuid && !(toSlotId in demandingSlots))
      --equippedCount
    if (equippedCount < 1) {
      if (draggedDropData.scheme?.atLeastOne == targetDropData.scheme?.atLeastOne) {
        equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
        return true
      }
      local demandingInfo = getDemandingSlotsInfo(parentItemGuid, slotType)
      if ((demandingInfo ?? "").len() > 0) {
        popupsState.addPopup({
          id = "swap_items_error"
          text = demandingInfo
          styleName = "error"
        })
        return false
      }
    }
  }

  local equippedItems = getSoldierItemSlots(parentItemGuid)
  local toItem = equippedItems.findvalue(@(d)
    d.slotType == toSlotType && d.slotId == toSlotId)?.item
  if (toItem != null)
    swapItems(toOwnerGuid, toSlotType, toSlotId, parentItemGuid, slotType, slotId)
  else
    equipItem(itemGuid, toSlotType, toSlotId, toOwnerGuid)
  return true
}

local hintWithIcon = @(icon, locId) {
  flow = FLOW_HORIZONTAL
  gap = gap
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_STEXT
      validateStaticText = false
      font = Fonts.fontawesome
      text = fa[icon]
      fontSize = ::hdpx(12)
      color = fadedTxtColor
    }
    {
      rendObj = ROBJ_DTEXT
      text = ::loc(locId)
      font = Fonts.tiny_text
      color = fadedTxtColor
    }
  ]
}

local dragAndDropHint = hintWithIcon("hand-paper-o", "hint/equipDragAndDrop")
local quickEquipHint = hintWithIcon("reply", "hint/equipDoubleClick")
local quickUnequipHint = hintWithIcon("share", "hint/unequipDoubleClick")

local makeToolTip = ::kwarg(function(item, canDrag, isEquipped, canChange, soldierWatch) {
  if (!item?.gametemplate)
    return null

  local hints = []
  if (!isGamepad.value && item?.guid && !(item?.isShopItem ?? false)) {
    if (canDrag)
      hints.append(dragAndDropHint)
    if (canChange)
      hints.append(isEquipped ? quickUnequipHint : quickEquipHint)
  }
  local desc = getItemDesc(item)
  return tooltipBox(@() {
    watch = isGamepad
    minWidth = hdpx(350)
    maxWidth = hdpx(500)
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            font = Fonts.medium_text
            text = getItemName(item)
            color = defTxtColor
          }
          statusTier(item)
        ]
      }
      desc == "" ? null : {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        maxWidth = hdpx(500)
        text = desc
        color = Color(180, 180, 180, 120)
      }
      mkTooltipStatus(item, soldierWatch)
      hints.len() <= 0 ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        minWidth = SIZE_TO_CONTENT
        color = Color(0, 0, 0, 224)
        flow = FLOW_VERTICAL
        margin = [bigGap, 0, 0, 0]
        gap = bigGap
        children = hints
      }
    ]
  })
})

local defBgStyle = @(sf, selected) { rendObj = ROBJ_SOLID, color = listBgColor(sf, selected) }
local function defIconCtor(item, soldierWatch) {
  local demandsWatch = mkItemDemands(item, soldierWatch.value?.sClass)
  return @() {
    watch = [demandsWatch, soldierWatch]
    children = statusIconCtor(demandsWatch.value)
  }
}

local itemCountRarity = @(item, flags, isSelected) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_CENTER
  children = [
    statusTier(item)
    defAmountCtor(item, flags, isSelected)
  ]
}

local mkUnseenSign = @(hasUnseenSign) @() {
  watch = hasUnseenSign
  children = hasUnseenSign.value ? unseenSignal : null
}

local mkUpgradableSign = @(sf, selected) {
  size = [hdpx(20), hdpx(20)]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  fontSize = hdpx(15)
  color = listTxtColor(sf, selected)
  text = fa["gear"]
}

local mkSigns = @(upgradeData, sf, selected, hasUnseenSign) function() {
  local canBeUpgraded = upgradeData.value?.isUpgradable && upgradeData.value?.hasEnoughParts
  return {
    watch = [upgradeData, hasUnseenSign]
    flow = FLOW_HORIZONTAL
    children = [
      canBeUpgraded ? mkUpgradableSign(sf, selected) : null
      !hasUnseenSign.value ? null
        : canBeUpgraded ? unseenSignal.__update({size = [hdpx(16), hdpx(22)]})
        : unseenSignal
    ]
  }
}

local function mkItem(slotId = null, item = null, slotType = null, itemSize = defItemSize,
  emptySlotChildren = defSlotnameCtor, scheme = null, itemCtor = defItemCtor,
  statusCtor = defIconCtor, soldierGuid = null, isInteractive = true, isDisabled = false, canDrag = true,
  bgStyle = defBgStyle, selectedKey = Watched(null), selectKey = null, isXmb = false,
  bgColor = defBgColor, pauseTooltip = Watched(false), onClickCb = null, onHoverCb = null, isLocked = false,
  onDoubleClickCb = null, onResearchClickCb = null, mods = null, hasUnseenSign = Watched(false)) {

  if (isDisabled)
    isInteractive = false

  local soldier = ::Computed(@() objInfoByGuid.value?[soldierGuid])
  if (::type(item) == "string")
    item = objInfoByGuid.value?[item]
  local itemDesc = { item, slotType, soldierGuid, slotId, scheme }

  local stateFlags = Watched(0)
  selectKey = selectKey ?? (item != null
    ? (item?.isShopItem ? item?.basetpl : item?.guid)
    : "_".concat(soldierGuid, slotType ?? "", slotId ?? ""))
  local group = ::ElemGroup()
  local dropData = { item, slotType, slotId, scheme }

  local canDrop = function(data) {
    if (dropData == data)
      return true
    if (data?.slotType == null && dropData.slotType == null)
      return false // drag from storage to storage
    return canEquip(data?.item, scheme) && ("guid" not in item || canEquip(item, data?.scheme))
  }

  return function() {
    local flags = stateFlags.value
    local isSelected = selectedKey.value == selectKey
    local upgradeData = mkItemUpgradeData(item)
    local children = (item?.guid ?? "") != "" ? [
          itemCtor(item, slotType, itemSize, isSelected, flags, group)
          itemCountRarity(item, flags, isSelected)
          {
            flow = FLOW_HORIZONTAL
            gap = 0
            children = [
              statusCtor(item, soldier)
              mkSigns(upgradeData, flags, isSelected, hasUnseenSign)
            ]
          }
          mods
        ]
      : item != null ? [
          itemCtor(item, slotType, itemSize, isSelected, flags, group)
          {
            hplace = ALIGN_RIGHT
            vplace = ALIGN_TOP
            children = statusTier(item)
          }
          {
            flow = FLOW_HORIZONTAL
            children = [
              statusCtor(item, soldier)
              mkUnseenSign(hasUnseenSign)
            ]
          }
        ]
      : isLocked ? slotBlockedCtor(isSelected, flags, onResearchClickCb
          ? @() onResearchClickCb(soldier.value, slotType, slotId)
          : null)
      : [ emptySlotChildren(slotType, itemSize, isSelected, flags, group)
          mkUnseenSign(hasUnseenSign)
        ]

    return {
      watch = [stateFlags, selectedKey, itemDragData, objInfoByGuid]
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_BOX
      fillColor = (item?.isShowDebugOnly ?? false) ? 0xFF003366
        : isDisabled ? fadedTxtColor
        : isLocked ? blockedBgColor
        : bgColor
      borderWidth = !isLocked && canDrop(itemDragData.value) ? 1 : 0
      children = {
        size = itemSize
        eventPassThrough = (item != null && canDrag)
        transform = {}
        behavior = isInteractive ? Behaviors.DragAndDrop : Behaviors.Button
        group = group
        function onDragMode(on, data) {
          if (on)
            sound_play("ui/inventory_item_take")
          itemDragData.update(on ? data : null)
        }
        function onClick(event) {
          if (!isInteractive || onClickCb == null)
            return
          onClickCb(itemDesc.__merge({ rectOrPos = event.targetRect }))
        }
        function onDoubleClick(event) {
          if (isLocked || !isInteractive || onDoubleClickCb == null)
            return
          onDoubleClickCb(itemDesc.__merge({ rectOrPos = event.targetRect }))
        }
        function onDrop(data) {
          if (isLocked)
            return
          local isItemEquipping = trySwapItems(soldierGuid, dropData, data)
          if (isItemEquipping)
            sound_play("ui/inventory_item_place")
        }
        function onHover(on) {
          curHoveredItem(on ? item : null)
          onHoverCb?(on)
          cursors.tooltip.state(on && item && !pauseTooltip.value
            ? makeToolTip({
                item = item
                canDrag = canDrag
                isEquipped = slotType != null
                canChange = canDrag && onDoubleClickCb != null
                soldierWatch = soldier
              })
            : null)
        }
        dropData = (item != null && canDrag) ? dropData : null
        canDrop = canDrop
        children = children
        clipChildren = true
        onElemState = isInteractive ? (@(sf) stateFlags(sf)) : null
      }.__update(bgStyle(flags, isSelected))
        .__update(isXmb ? { xmbNode = ::XmbNode() } : {})
        .__update(item != null && canDrag ? { cursor = cursors.draggable } : {})
    }
  }
}

return {
  mkItem = ::kwarg(mkItem)
  defSlotnameCtor
}
 