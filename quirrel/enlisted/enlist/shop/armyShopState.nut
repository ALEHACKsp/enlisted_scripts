local frp = require("std/frp.nut")
local { mkOnlinePersistentFlag } = require("enlist/options/mkOnlinePersistentFlag.nut")
local { seenShopItems, excludeShopItemSeen } = require("unseenShopItems.nut")
local { onlineSettingUpdated } = require("enlist/options/onlineSettings.nut")
local openUrl = require("enlist/openUrl.nut")
local { configs } = require("enlisted/enlist/configs/configs.nut")
local { getShopUrl, getUrlByGuid } = require("enlist/shop/shopUrls.nut")
local extAutoRefreshTimer = require("enlist/state/extAutoRefreshTimer.nut")
local userInfo = require("enlist/state/userInfo.nut")
local { curSection, setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")
local { permissions } = require("globals/client_user_permissions.nut")
local {
  goodsInfo, collectMarketIds, requestGoodsInfo
} = require("enlist/shop/goodsAndPurchases_pc.nut")
local {
  curArmyData, curArmy, curCampItemsCount, armySquadsById, itemCountByArmy
} = require("enlisted/enlist/soldiers/model/state.nut")
local { allItemTemplates } = require("enlisted/enlist/soldiers/model/all_items_templates.nut")
local { hasCurArmyReserve } = require("enlisted/enlist/soldiers/model/reserve.nut")
local {
  buy_shop_item, barter_shop_item, check_purchases
} = require("enlisted/enlist/meta/clientApi.nut")
local { purchasesCount } = require("enlisted/enlist/meta/profile.nut")
local { hasPremium } = require("enlisted/enlist/currency/premium.nut")
local platform = require("globals/platform.nut")
local xdkStore = platform.is_xdk ? require("xbox.store") : null
local gdkStore = platform.is_gdk ? require("enlist/xbox_gdk/store.nut") : null
local ps4store = platform.is_sony ? require("enlist/ps4/store.nut") : null

local AUTO_REFRESH_DELAY = 30.0 //sec between several window inactivates without mve to shop link
local CHECK_PURCHASED_PERIOD = 10.0 //sec to check purchases after return back to game after shop link
local MAX_PURCHASES_CHECK = 6 //amount of purchases check after back from shopLink

local shopOrdersUsed = mkOnlinePersistentFlag("hasShopOrdersUsed")
local hasShopOrdersUsed = shopOrdersUsed.flag
local shopOrdersUsedActivate = shopOrdersUsed.activate

local shopItemsBase = ::Computed(@() configs.value?.shop_items ?? {})
local isDebugShowPermission = ::Computed(@()
  permissions.value?[userInfo.value?.userId].debug_shop_show ?? false )

local marketIds = keepref(::Computed(@() shopItemsBase.value.values()
  .map(@(s) (s?.purchaseGuid ?? "") != "" ? { guid = s.purchaseGuid } : null)
  .filter(@(m) m != null)))

collectMarketIds(marketIds)
marketIds.subscribe(requestGoodsInfo)

local shopConfig = ::Computed(@() configs.value?.shop_config ?? {})
local purchaseInProgress = ::Watched(null)

local function updateItemCost(sItem, purchases) {
  sItem.curItemCost <- clone sItem.itemCost
  sItem.curShopItemPrice <- clone sItem.shopItemPrice
  local amount = purchases?[sItem?.id].amount ?? 0
  if (amount <= 0)
    return sItem

  sItem.curShopItemPrice.price += amount * (sItem?.shopItemPriceInc ?? 0)
  foreach (itemId, cost in sItem?.itemCostInc ?? {})
    sItem.curItemCost[itemId] <- (sItem.curItemCost?[itemId] ?? 0) + amount * cost
  return sItem
}

local shopItems = ::Computed(@() shopItemsBase.value
  .map(@(item, guid) updateItemCost(
    item.__merge({ guid = guid })
      .__update(goodsInfo.value?[item?.purchaseGuid] ?? {}),
    purchasesCount.value)))

local function getPayItemsData(shopItem, campItems) {
  local { curItemCost } = shopItem
  if (curItemCost.len() == 0)
    return null
  local allAvailableItems = campItems.filter(@(item) (item.basetpl in curItemCost))
  local res = {}
  foreach (payItemTpl, cost in curItemCost) {
    local requiredItems = cost
    local inventoryItems = allAvailableItems.filter(@(item) item.basetpl == payItemTpl)
    foreach (i in inventoryItems) {
      res[i.guid] <- ::min(i.count, requiredItems)
      requiredItems -= i.count
      if (requiredItems <= 0)
        break
    }
    if (requiredItems > 0)
      return null
  }
  return res
}

local function isAvailableBySquads(shopItem, squadsByArmyV) {
  return (shopItem?.squads ?? []).findindex(@(sqData)
    squadsByArmyV?[sqData.armyId][sqData.squadId].locked != true) == null
}

local isAvailableByLimit = @(sItem, purchases)
  (sItem?.limit ?? 0) <= 0 || sItem.limit > (purchases?[sItem?.id].amount ?? 0)

local isAvailableByPermission = @(sItem, isDebugShow)
  !(sItem?.isShowDebugOnly ?? false) || isDebugShow

local isAvailableByArmyLevel = @(sItem, curArmyLevel)
  (sItem?.requirements.armyLevel ?? 0) <= curArmyLevel

local getMinRequiredArmyLevel = @(goods) goods.reduce(function(res, sItem) {
  local level = sItem?.requirements.armyLevel ?? 0
  return level <= 0 ? res
    : res <= 0 ? level
    : min(level, res)
}, 0)

local curArmyShopInfo = ::Computed(function() {
  local armyData = curArmyData.value
  local goods = shopItems.value
    .filter(@(i) i.armyId == armyData?.guid
      && !(i?.isHidden ?? false)
      && isAvailableBySquads(i, armySquadsById.value)
      && isAvailableByLimit(i, purchasesCount.value)
      && isAvailableByPermission(i, isDebugShowPermission.value))

  local unlockLevel = getMinRequiredArmyLevel(goods)
  local curArmyLevel = armyData?.level ?? 0
  goods = goods.filter(@(i) isAvailableByArmyLevel(i, curArmyLevel))
    .values()
    .sort(@(a, b) b.inLineProirity <=> a.inLineProirity)
  return { unlockLevel, goods }
})

local curArmyShopItems = Computed(@() curArmyShopInfo.value.goods)

local curArmyShopLines = ::Computed(function() {
  local linesCount = 0
  foreach(item in curArmyShopItems.value)
    linesCount = ::max(linesCount, item.offerLine + 1)

  local res = array(linesCount).map(@(v) [])
  foreach(item in curArmyShopItems.value)
    res[item.offerLine].append(item)

  return res
})

local curArmyShopCrates = ::Computed(@() curArmyShopItems.value.map(@(i) i.crateId)
  .filter(@(c) c != ""))

local curShopCurrencies = ::Computed(@()
  curArmyShopItems.value.reduce(@(res, shopItem) res.__merge(shopItem.itemCost), {}))

local curArmyCurrency = ::Computed(function() {
  local armyId = curArmy.value
  local res = {}
  foreach (currencyTpl, _ in curShopCurrencies.value)
    res[currencyTpl] <- (res?[currencyTpl] ?? 0)
      + (curCampItemsCount.value?[currencyTpl] ?? 0)

  return res.filter(@(count, tpl) count > 0
    || !(allItemTemplates.value?[armyId][tpl].isZeroHidden ?? true))
})

local { refreshOnWindowActivate } = extAutoRefreshTimer({
  refresh = check_purchases
  refreshDelaySec = AUTO_REFRESH_DELAY
})
local itemsRefreshOnWindowActivate =
  @() refreshOnWindowActivate(MAX_PURCHASES_CHECK, CHECK_PURCHASED_PERIOD)

local function getBuyRequirementError(shopItem) {
  local requirements = shopItem?.requirements
  if ((requirements?.hasArmyReserve ?? false) && !hasCurArmyReserve.value)
    return {
      text = ::loc("shop/freePlaceForReserve")
      resolveText = ::loc("retraining/btn")
      resolveCb = function() {
        setCurSection("ACADEMY")
      }
      solvableByPremium = !hasPremium.value
    }
  return null
}

local function canBarterItem(item, armyItemCount) {
  foreach (payItemTpl, cost in item.curItemCost)
    if ((armyItemCount?[payItemTpl] ?? 0) < cost)
      return false
  return true
}

local curAvailableShopItems = ::Computed(function() {
  local itemCount = itemCountByArmy.value
  return curArmyShopItems.value.filter(@(item) item.offerContainer == ""
    && item.itemCost.len() > 0
    && canBarterItem(item, itemCount?[item.armyId] ?? {}))
})

local curUnseenAvailableShopItems = ::Computed(function() {
  local seen = seenShopItems.value ?? {}
  return onlineSettingUpdated.value
    ? curAvailableShopItems.value.filter(@(item) item.guid not in seen)
    : {}
})

local curUnseenAvailableShopGroups = ::Computed(function() {
  local unseenItems = curUnseenAvailableShopItems.value
  return curArmyShopItems.value.filter(@(item) item.offerContainer != ""
    && unseenItems.findvalue(@(i) i.offerGroup == item.offerContainer) != null)
})

curAvailableShopItems.subscribe(function(v) {
  local seen = seenShopItems.value ?? {}
  if (seen.len() == 0)
    return

  local excludeList = seen.filter(@(v, guid) curAvailableShopItems.value
    .findindex(@(i) i.guid == guid) == null)
    .keys()
  if (excludeList.len() == 0)
    return

  excludeShopItemSeen(excludeList)
})

local function barterShopItem(shopItem, payData) {
  if (purchaseInProgress.value != null)
    return

  local armyId = shopItem.armyId
  purchaseInProgress(shopItem)
  barter_shop_item(armyId, shopItem.guid, payData, function(res) {
    purchaseInProgress(null)
    shopOrdersUsedActivate()
  })
}

local function buyShopItem(shopItem, currencyId, price) {
  if (purchaseInProgress.value != null)
    return

  local armyId = shopItem.armyId
  purchaseInProgress(shopItem)
  buy_shop_item(armyId, shopItem.guid, currencyId, price, function(res) {
    purchaseInProgress(null)
  })
}

local function openPurchaseUrl(url) {
  local currencyShopOpen = @() openUrl(url)
  if (platform.is_xdk) {
    currencyShopOpen = @() xdkStore.show_marketplace(xdkStore.Consumable)
  }
  else if (platform.is_gdk) {
    currencyShopOpen = @() gdkStore.show_marketplace(gdkStore.PKConsumable)
  }
  else if (platform.is_sony) {
    currencyShopOpen = @() ps4store.open_store("ENLISTEDCOINS", false, ps4store.refresh_inventory)
  }
  currencyShopOpen()
  itemsRefreshOnWindowActivate()
}

local function buyItemByGuid(guid) {
  local url = getUrlByGuid(guid) ?? getShopUrl()
  if (url == null)
    return false
  openPurchaseUrl(url)
  return true
}

userInfo.subscribe(function(u) {
  if (u != null)
    check_purchases()
})

local function blinkCurrencies() {
  foreach(currencyTpl, count in curArmyCurrency.value)
    if (count > 0)
      ::anim_start($"blink_{currencyTpl}")
}

local function setupBlinkCurrencies() {
  if (curSection.value != "SHOP" || hasShopOrdersUsed.value)
    ::gui_scene.clearTimer(blinkCurrencies)
  else
    ::gui_scene.setInterval(2.5, blinkCurrencies)
}

setupBlinkCurrencies()
frp.subscribe([curSection, hasShopOrdersUsed], @(v) setupBlinkCurrencies())

return {
  shopItems
  shopConfig
  curArmyShopInfo
  curArmyShopItems
  curArmyShopLines
  curArmyShopCrates
  curArmyCurrency
  purchaseInProgress
  getPayItemsData
  buyShopItem
  barterShopItem
  buyItemByGuid
  openPurchaseUrl
  getBuyRequirementError
  isAvailableByLimit
  hasShopOrdersUsed
  curUnseenAvailableShopItems
  curUnseenAvailableShopGroups
}
 