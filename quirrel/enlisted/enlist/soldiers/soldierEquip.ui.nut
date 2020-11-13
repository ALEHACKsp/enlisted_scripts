local { smallPadding, bigPadding, soldierWndWidth, unitSize } = require("enlisted/enlist/viewConst.nut")
local { statusIconLocked } =  require("enlisted/style/statusIcon.nut")
local fa = require("daRg/components/fontawesome.map.nut")
local { note } = require("enlisted/enlist/components/defcomps.nut")
local { allItemTemplates } = require("enlisted/enlist/soldiers/model/all_items_templates.nut")

local { curArmy, objInfoByGuid, getSoldierItemSlots } = require("model/state.nut")
local { classSlotLocksByArmy } = require("enlisted/enlist/researches/researchesSummary.nut")
local { equipGroups, slotTypeToEquipGroup } = require("model/config/equipGroups.nut")
local { openSelectItem } = require("model/selectItemState.nut")
local { curUnseenAvailableUpgrades } = require("model/unseenUpgrades.nut")
local mkItemWithMods = require("mkItemWithMods.nut")
local { defSlotnameCtor } = require("components/itemComp.nut")
local { soldierSlotsCount, soldierSlotsLocked } = require("model/soldierSlotsCount.nut")
local { promoSmall } = require("enlisted/enlist/currency/pkgPremiumWidgets.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { getLinkedArmyName } = require("enlisted/enlist/meta/metalink.nut")
local { unseenSoldiersWeaponry } = require("model/unseenWeaponry.nut")

const opacityForDisabledItems = 0.3
const MAX_ITEMS_IN_ROW = 4
const MAX_SLOT_TYPES_IN_ROW = 3

local function openEquipMenu(p /*onClick params from mkItem*/) {
  openSelectItem({
    armyId = curArmy.value
    ownerGuid = p?.soldierGuid
    slotType = p?.slotType
    slotId = p?.slotId
  })
}

local mkItem = function(params) {
  return mkItemWithMods((params ?? {}).__merge({
    onClickCb = openEquipMenu
  }))
}

local soldierWndInnerWidth = soldierWndWidth - 2 * bigPadding

local function collectSlots(slotType, totalSlots, lockedSlots, slotsItems, soldierGuid) {
  local soldierData = objInfoByGuid.value?[soldierGuid]
  local isAvailable = true
  if (soldierData && slotType) {
    local armyId = getLinkedArmyName(soldierData)
    local sClass = soldierData?.sClass ?? "unknown"
    isAvailable = (classSlotLocksByArmy.value?[armyId][sClass] ?? []).indexof(slotType) == null
  }

  local emptySlot = { item = null, slotType = slotType, slotId = -1, isLocked = !isAvailable }
  local slots = slotsItems.filter(@(s) s.slotType == slotType)
    .map(@(s) emptySlot.__merge(s))
  if (totalSlots <= 0)
    return slots.len() > 0 ? slots : [emptySlot]

  local slotsMap = {}
  slots.each(@(s) slotsMap[s.slotId] <- s)
  return array(totalSlots + lockedSlots).map(@(_, slotId) slotId < totalSlots
    ? slotsMap?[slotId] ?? emptySlot.__merge({ slotId = slotId })
    : emptySlot.__merge({ slotId = slotId, isLocked = true }))
}

local warningMark = {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  rendObj = ROBJ_STEXT
  font = Fonts.fontawesome
  fontSize = ::hdpx(40)
  color = statusIconLocked
  text = fa["warning"]
  validateStaticText = false
  animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1.0, play = true, loop = true, easing = CosineFull }]
}

local emptySlotWithWarningChildren = @(slotType, itemSize, isSelected, sf, group) {
  size = flex()
  children = [
    warningMark
    defSlotnameCtor(slotType, itemSize, isSelected, sf, group)
  ]
}

local mkItemsBlock = ::kwarg(function(
  soldierGuid, canManage, slots = [], itemCtor = mkItem, numInRow = MAX_ITEMS_IN_ROW,
  gap = smallPadding
) {
  local itemsNum = min(slots.len(), numInRow)
  if (itemsNum == 0)
    return null

  local itemWidth = (soldierWndInnerWidth - gap * (itemsNum - 1)) / itemsNum
  local itemSize = [itemWidth, min(itemWidth, unitSize * 2)]
  return wrap(
    slots.map(@(slot) itemCtor(
      slot.__merge({
        soldierGuid = soldierGuid
        itemSize = itemSize
        isInteractive = canManage
        emptySlotChildren = slot.hasWarning ? emptySlotWithWarningChildren : defSlotnameCtor
        hasUnseenSign = slot.isUnseen
      }))),
    { width = soldierWndInnerWidth, hGap = gap, vGap = gap, hplace = ALIGN_CENTER }
  )
})

local function getWarningSlotTypes(slotsItems, groupSchemes) {
  local equipped = {}
  local slotTypeToGroup = {}
  foreach(slot in groupSchemes)
    if ((slot?.atLeastOne ?? "") != "") {
      equipped[slot.atLeastOne] <- false
      slotTypeToGroup[slot.slotType] <- slot.atLeastOne
    }
  foreach(slotData in slotsItems) {
    if (slotData.item == null)
      continue
    local group = slotTypeToGroup?[slotData.slotType]
    if (group in equipped)
      equipped[group] = true
  }
  return slotTypeToGroup.map(@(group) !equipped[group])
    .filter(@(v) v == true)
}

local mkItemsChapter = ::kwarg(function mkItemsChapterImpl(
  equipGroup, soldier, canManage, slotsCount, slotsLocked, itemCtor = mkItem
) {
  local header = "locId" in equipGroup ? note(::loc(equipGroup.locId)) : null
  local groupSchemes = (soldier?.equipScheme ?? {})
    .filter(@(_, slotType) slotTypeToEquipGroup?[slotType] == equipGroup)
    .map(@(scheme, slotType) scheme.__merge({ slotType }))
    .values()
  if (groupSchemes.len() == 0)
    return null

  groupSchemes.sort(@(a, b) a.uiOrder <=> b.uiOrder)
  local soldierGuid = soldier.guid
  return function() {
    local slotsItems = getSoldierItemSlots(soldierGuid)
    local warningSlotTypes = getWarningSlotTypes(slotsItems, groupSchemes)

    local rowsData = []
    local lastRow = null
    foreach(scheme in groupSchemes) {
      local { slotType, isPrimary = false, isDisabled = false } = scheme
      local currentSlotsCount = slotsCount.value?[slotType] ?? 0
      local lockedSlotsCount = slotsLocked.value?[slotType] ?? 0
      local slotsList = collectSlots(slotType, currentSlotsCount, lockedSlotsCount, slotsItems, soldierGuid)

      slotsList.each(@(s) s.__update({
        item = objInfoByGuid.value?[s.item?.guid]
        scheme = scheme
        hasWarning = warningSlotTypes?[slotType] ?? false
        isDisabled = isDisabled
        isUnseen = ::Computed(@() s?.item.basetpl in curUnseenAvailableUpgrades.value
          || (unseenSoldiersWeaponry.value?[soldierGuid][slotType] ?? false))
      }))

      local isAlone = isPrimary || slotsList.len() > 1
      if (!isAlone && lastRow != null && lastRow.slots.len() < MAX_SLOT_TYPES_IN_ROW) {
        lastRow.slots.extend(slotsList)
        continue
      }

      rowsData.append({
        slots = slotsList
        soldierGuid
        canManage
        itemCtor
        numInRow = isPrimary ? 1 : MAX_ITEMS_IN_ROW
      })
      lastRow = isAlone ? null : rowsData.top()
    }

    return {
      watch = [slotsCount, slotsLocked, objInfoByGuid, allItemTemplates]
      size = [soldierWndInnerWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [ header ]
        .extend(rowsData.map(@(s) mkItemsBlock(s)))
    }
  }
})

local function soldierEquip(
  soldier, canManage = true, selectedKeyWatch = Watched(null), onDoubleClickCb = null,
  onResearchClickCb = null
) {
  local itemCtor = @(p) mkItem(p.__merge({
    selectedKey = selectedKeyWatch
    onDoubleClickCb = onDoubleClickCb
    onResearchClickCb = onResearchClickCb
  }))

  local groupParams = {
    soldier
    canManage
    itemCtor
    slotsCount = soldierSlotsCount(soldier.guid, soldier?.equipScheme ?? {})
    slotsLocked = soldierSlotsLocked(soldier.guid, soldier?.equipScheme ?? {})
  }

  local children = equipGroups.map(@(equipGroup)
    mkItemsChapter(groupParams.__merge({ equipGroup = equipGroup })))

  children.append(@() {
    watch = monetization
    size = flex()
    valign = ALIGN_BOTTOM
    children = monetization.value
      ? promoSmall("premium/buyForSquads", null, "soldier_equip", "soldier_inventory")
      : null
  })

  return {
    children = children
    flow = FLOW_VERTICAL
    gap = bigPadding
    size = flex()
  }
}

return ::kwarg(soldierEquip) 