local msgbox = require("ui/components/msgbox.nut")
local { equipGroups } = require("config/equipGroups.nut")
local {
  curCampSoldiers, getEquippedItemGuid, objInfoByGuid, armoryByArmy, itemCountByArmy,
  getScheme, getItemOwnerSoldier, curCampItems
} = require("enlisted/enlist/soldiers/model/state.nut")
local { equipItem } = require("enlisted/enlist/soldiers/model/itemActions.nut")
local {
  classWeaponUsageByArmy, classSlotLocksByArmy
} = require("enlisted/enlist/researches/researchesSummary.nut")
local {
  allItemTemplates, findItemTemplate
} = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local {
  prepareItems, addShopItems, itemsSort
} = require("enlisted/enlist/soldiers/model/items_list_lib.nut")
local { itemTypesInSlots } = require("all_items_templates.nut")
local soldierClasses = require("enlisted/enlist/soldiers/model/soldierClasses.nut")
local { soldierSlotsCount, soldierSlotsLocked } = require("soldierSlotsCount.nut")
local { logerr } = require("dagor.debug")
local { getLinkedArmyName, isObjLinkedToAnyOfObjects } = require("enlisted/enlist/meta/metalink.nut")
local {
  focusResearch, findResearchWeaponUnlock, findResearchSlotUnlock
} = require("enlisted/enlist/researches/researchesFocus.nut")
local { getObjectName } = require("enlisted/enlist/soldiers/itemsInfo.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { unseenTiers } = require("unseenWeaponry.nut")


local selectParamsList = persist("selectParamsList", @() Watched([]))
local selectParams = ::Computed(@()
  selectParamsList.value.len() ? selectParamsList.value.top() : null)

local curEquippedItem = ::Computed(function() {
  local { ownerGuid = null, slotType = null, slotId = null } = selectParams.value
  if (ownerGuid == null || slotType == null)
    return null
  local guid = getEquippedItemGuid(curCampItems.value, ownerGuid, slotType, slotId)
  return objInfoByGuid.value?[guid]
})

local curInventoryItem = Watched(null)
curCampItems.subscribe(@(_) curInventoryItem(null))

local viewItem = ::Computed(@() curInventoryItem.value ?? curEquippedItem.value) // last selected or current item

local calcItems = function(params, objInfoByGuidV, armoryByArmyV) {
  local { armyId = null, filterFunc = @(tplId, tpl) true } = params
  if (!armyId)
    return []

  local itemsList = prepareItems((armoryByArmyV?[armyId] ?? [])
    .filter(@(item)
      item && filterFunc(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl))))
  addShopItems(itemsList, armyId, @(tplId, tpl)
    filterFunc(tplId, tpl) && tpl.upgradeIdx == 0)
  itemsList.sort(itemsSort)
  return itemsList
}

local calcOther = function(params, armoryByArmyV, itemTypesInSlotsV) {
  local { slotType = null, armyId = null, filterFunc = @(tplId, tpl) true } = params
  if (!armyId)
    return []

  local allTypes = itemTypesInSlotsV?[slotType]
  local otherList = (armoryByArmyV?[armyId] ?? [])
    .filter(@(item) item
      && !filterFunc(item.basetpl, findItemTemplate(allItemTemplates, armyId, item.basetpl))
      && allTypes?[item?.itemtype])

  otherList = prepareItems(otherList)
  addShopItems(otherList, armyId, @(tplId, tpl)
    (allTypes?[tpl.itemtype] ?? false) && !filterFunc(tplId, tpl) && tpl.upgradeIdx == 0)
  otherList.sort(itemsSort)
  return otherList
}

local slotItems = ::Computed(@()
  calcItems(selectParams.value, objInfoByGuid.value, armoryByArmy.value))

local otherSlotItems = ::Computed(@()
  calcOther(selectParams.value, armoryByArmy.value, itemTypesInSlots.value))

local mkDefaultFilterFunc = function(showItemTypes = [], showItems = []) {
  local isFilterTypes = (showItemTypes?.len() ?? 0) != 0
  return (showItems?.len() ?? 0) != 0
    ? (isFilterTypes
      ? @(tmpl, item)
          showItems.indexof(tmpl) != null || showItemTypes.indexof(item?.itemtype) != null
      : @(tmpl, _) showItems.indexof(tmpl) != null)
    : (isFilterTypes
      ? @(_, item) showItemTypes.indexof(item?.itemtype) != null
      : @(_0, _1) true)
}

local paramsForPrevItems = ::Computed(function() {
  local { soldierGuid = null, ownerGuid = null, armyId = null } = selectParams.value
  if (soldierGuid != null)
    return null

  local ownerItem = objInfoByGuid.value?[ownerGuid]
  if (ownerItem == null)
    return null

  return {
    armyId = armyId
    ownerGuid = ownerGuid
    soldierGuid = soldierGuid
    filterFunc = mkDefaultFilterFunc([ownerItem?.itemtype])
    ownerName = getObjectName(ownerItem)
  }
})

local prevItems = ::Computed(@()
  calcItems(paramsForPrevItems.value, objInfoByGuid.value, armoryByArmy.value)
    .filter(@(item) "guid" in item))

local function getItemPartsNumber(item, itemCount) {
  local disassemblyId = item?.disassembly
  if (disassemblyId == null)
    return 0
  local armyId = getLinkedArmyName(item)
  return itemCount?[armyId][disassemblyId] ?? 0
}
local mkItemPartsNumberComp = @(item) ::Computed(@() getItemPartsNumber(item, itemCountByArmy.value))
local viewItemParts = ::Computed(@() getItemPartsNumber(viewItem.value, itemCountByArmy.value))

local viewSoldierInfo = ::Computed(@()
  objInfoByGuid.value?[selectParams.value?.soldierGuid])

local function openSelectItem(armyId, ownerGuid, slotType, slotId) {
  local ownerItem = objInfoByGuid.value?[ownerGuid]
  if (!ownerItem) {
    logerr($"Not found item info to select item {ownerGuid}")
    return
  }
  local scheme = getScheme(ownerItem, slotType)
  if (!scheme) {
    logerr($"Not found scheme for item {ownerGuid} slotType {slotType}")
    return
  }

  local soldierGuid = ownerGuid in curCampSoldiers.value
    ? ownerGuid
    : getItemOwnerSoldier(ownerGuid)?.guid

  local params = {
    armyId
    ownerGuid
    soldierGuid
    slotType
    slotId
    scheme
    filterFunc = mkDefaultFilterFunc(scheme?.itemTypes, scheme?.items)
    ownerName = getObjectName(ownerItem)
  }
  selectParamsList(function(l) {
    local idx = l.findindex(@(p) p?.soldierGuid == soldierGuid)
    if (idx != null)
      l.resize(idx)
    l.append(params)
  })
  curInventoryItem(null) // clear current selected inventory item on slot item selection
}

local function selectInsideListSlot(dir, wrap) {
  local { armyId, ownerGuid, slotType, slotId } = selectParams.value
  local curScheme = viewSoldierInfo.value?.equipScheme ?? {}
  local size = soldierSlotsCount(ownerGuid, curScheme).value?[slotType] ?? 0

  // if we're not wrapping, call came from selectSlot and we need to select locked slots too:
  if (!wrap)
    size += soldierSlotsLocked(ownerGuid, curScheme).value?[slotType] ?? 0

  if (size <= 1)
    return false
  slotId = slotId + dir
  if (wrap)
    slotId = (slotId + size) % size
  else if (slotId < 0 || slotId >= size)
    return false

  openSelectItem(armyId, ownerGuid, slotType, slotId)
  return true
}

local function selectSlot(dir) {
  local params = selectParams.value
  if (params == null || selectInsideListSlot(dir, false))
    return

  local { slotType } = params
  local { equipScheme = {} } = viewSoldierInfo.value

  local availableSlotTypes = equipGroups
    .map(@(g) g.slots.filter(@(s) (s in equipScheme) && !equipScheme[s]?.isDisabled))
    .map(@(v) v.sort(@(a, b) equipScheme[a].uiOrder <=> equipScheme[b].uiOrder))
    .reduce(@(a, val) a.extend(val), [])

  local slotIdx = availableSlotTypes.indexof(slotType)
  if (slotIdx == null)
    return

  slotIdx += dir
  if (slotIdx < 0 || slotIdx >= availableSlotTypes.len())
    return

  slotType = availableSlotTypes[slotIdx]
  local subslotsCount = soldierSlotsCount(viewSoldierInfo.value?.guid, equipScheme).value?[slotType] ?? 0
  local slotId = subslotsCount < 1 ? -1
    : dir < 0 ? subslotsCount - 1
    : 0

  local { armyId, ownerGuid } = params
  openSelectItem(armyId, ownerGuid, slotType, slotId)
}

local function close() {
  if (selectParamsList.value.len() > 0)
    selectParamsList(@(l) l.remove(l.len() - 1))
  if (selectParams.value == null)
    curInventoryItem(null) // clear current item on exit
}

local function checkSelectItem(item) {
  local { basetpl = null, itemtype = null, isShopItem = false } = item
  local soldier = viewSoldierInfo.value
  if (basetpl == null || soldier == null)
    return null

  if (isShopItem)
    return {
      text = ::loc("itemObtainInShop")
      resolveText = ::loc("GoToShop")
      resolveCb = function() {
        close()
        setCurSection("SHOP")
      }
    }

  local { guid = null, sClass = "unknown", equipScheme = {} } = soldier
  local sClassLoc = ::loc(soldierClasses?[sClass].locId ?? "unknown")
  local armyId = getLinkedArmyName(soldier)
  local usageLocked = classWeaponUsageByArmy.value?[armyId][sClass] ?? []
  if (usageLocked.indexof(basetpl) != null)
    return {
      text = ::loc("itemClassResearch", { soldierClass = sClassLoc })
      resolveText = ::loc("GoToResearch")
      resolveCb = function() {
        close()
        focusResearch(findResearchWeaponUnlock(item, soldier))
      }
    }

  local { slotType = null, slotId = -1, scheme = {} } = selectParams.value
  local slotsLocked = classSlotLocksByArmy.value?[armyId][sClass] ?? []
  local slotsCount = soldierSlotsCount(guid, equipScheme ?? {}).value?[slotType] ?? 0
  if (slotsLocked.indexof(slotType) != null || slotId >= slotsCount)
    return {
      text = ::loc("slotClassResearch", { soldierClass = sClassLoc })
      resolveText = ::loc("GoToResearch")
      resolveCb = function() {
        close()
        focusResearch(findResearchSlotUnlock(soldier, slotType, slotId))
      }
    }

  local itemTypes = equipScheme?[slotType].itemTypes ?? []
  local itemList = scheme?.items ?? []
  if ((itemTypes.len() != 0 || itemList.len() != 0)
      && itemTypes.indexof(itemtype) == null
      && itemList.indexof(basetpl) == null)
    return {
      text = ::loc("Not available for class", { soldierClass = sClassLoc })
    }

  return null
}

local function selectItem(item) {
  local checkSelectInfo = checkSelectItem(item)
  if (checkSelectInfo != null) {
    local buttons = [{ text = ::loc("Ok"), isCancel = true }]
    if (checkSelectInfo?.resolveCb != null)
      buttons.append({ text = checkSelectInfo.resolveText,
        action = checkSelectInfo.resolveCb,
        isCurrent = true })
    return msgbox.show({ text = checkSelectInfo.text, buttons = buttons })
  }

  local p = selectParams.value
  equipItem(item?.guid, p?.slotType, p?.slotId, p?.ownerGuid)
}

local unseenViewSlotTpls = Computed(function() {
  local { armyId = null } = selectParams.value
  local allUnseen = unseenTiers.value?[armyId].byTpl
  if (allUnseen == null)
    return {}

  local { tier = -1 } = curEquippedItem.value
  return allUnseen.filter(@(tplTier) tplTier > tier)
})

local function getModifyItemGuid(stackedItem, canBeLinked = false) {
  local profileItems = curCampItems.value
  local profileSoldiers = curCampSoldiers.value
  local stackedGuids = stackedItem?.guids ?? [stackedItem?.guid]
  foreach (guid in stackedGuids) {
    local item = profileItems?[guid]
    if (item == null)
      continue

    if (canBeLinked)
      return item.guid

    if (!isObjLinkedToAnyOfObjects(item, profileSoldiers ?? {}) &&
        !isObjLinkedToAnyOfObjects(item, profileItems ?? {}))
      return item.guid
  }
  return null
}

return {
  viewItem
  curInventoryItem
  viewItemParts
  curEquippedItem
  selectParams
  slotItems
  otherSlotItems //items fit to current slot, but not fit to current soldier class
  viewSoldierInfo
  paramsForPrevItems
  prevItems //when choose mod of not equipped item from items list
  unseenViewSlotTpls
  getModifyItemGuid

  openSelectItem = ::kwarg(openSelectItem)
  trySelectNext = @() selectInsideListSlot(1, true)
  selectNextSlot = @() selectSlot(1)
  selectPreviousSlot = @() selectSlot(-1)
  close
  checkSelectItem
  selectItem
  mkItemPartsNumberComp
} 