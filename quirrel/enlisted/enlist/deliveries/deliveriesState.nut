local serverTime = require("enlist/userstat/serverTime.nut")
local { deliveries, savedEvents } = require("enlisted/enlist/meta/profile.nut")
local { logerr } = require("dagor.debug")
local { curArmy } = require("enlisted/enlist/soldiers/model/state.nut")
local client = require("enlisted/enlist/meta/clientApi.nut")
local {
  getObjectsByLink, getObjectsByLinkSorted, getLinksByType, getLinkedArmyName
} = require("enlisted/enlist/meta/metalink.nut")


local refreshDailyDeliveries = ::Computed(function() {
  local events = getObjectsByLink(savedEvents.value, "daily_deliveries_refresh", "type")
  local res = {}
  foreach (savedEvent in events) {
    local armyId = getLinkedArmyName(savedEvent)
    if (armyId != null)
      res[armyId] <- savedEvent?.timestamp ?? -1
  }
  return res
})

local freeDeliveriesPurchaseTimestamp = ::Computed(function() {
  local events = getObjectsByLink(savedEvents.value, "daily_delivery_for_free", "type")
  return events?[0].timestamp ?? -1
})

local curArmySoldiersDeliveries = ::Computed(@()
  getObjectsByLinkSorted(deliveries.value, curArmy.value, "army")
    .filter(@(delivery) getLinksByType(delivery, "category")?[0] == "soldiers")
)

local curArmySoldiersDelivery = ::Computed(@()
  curArmySoldiersDeliveries.value.findvalue(@(val) !val?.hasReceived))


local curArmyDailyDeliveries = ::Computed(@()
  getObjectsByLinkSorted(deliveries.value, curArmy.value, "army")
    .filter(@(delivery) getLinksByType(delivery, "category")?[0] == "daily")
)

local curArmyDailyDelivery = ::Computed(@()
  curArmyDailyDeliveries.value.findvalue(@(val) !val?.hasReceived))

local curArmyDailyDeliveriesRefreshTime = ::Computed(function() {
  local refreshTime = refreshDailyDeliveries.value?[curArmy.value] ?? 0
  return refreshTime > 0
    ? ::max(refreshTime - serverTime.value, 0)
    : -1
})

local freeDeliveriesPurchaseTime = ::Computed(function() {
  local purchaseTime = freeDeliveriesPurchaseTimestamp.value
  return purchaseTime > 0
    ? ::max(purchaseTime - serverTime.value, 0)
    : -1
})

local function requestDelivery(armyId, category, cb = @(res) null) {
  client.request_delivery(armyId, category, cb)
}

local function openDelivery(guid) {
  if (guid == null) {
    logerr("Empty delivery guid!")
    return
  }
  client.open_delivery(guid)
}

local function purchaseDelivery(guid, cost) {
  if (guid == null) {
    logerr("Empty delivery guid!")
    return
  }
  client.purchase_delivery(guid, cost)
}

local isDeliveriesUpdating = Watched(false)

serverTime.subscribe(function(t) {
  foreach (armyId, refreshTime in refreshDailyDeliveries.value ?? {})
    if (!(isDeliveriesUpdating.value ?? false) && refreshTime > 0 && refreshTime <= t) {
      isDeliveriesUpdating(true)
      requestDelivery(armyId, "daily", function(res) {
        isDeliveriesUpdating(false)
      })
    }
})

local sceneParams = persist("sceneParams", @() Watched(null))
local function openSoldiersScene() {
  sceneParams({ category = "soldiers" })
}

local function openDailyScene() {
  sceneParams({ category = "daily" })
}

return {
  sceneParams = sceneParams
  openDailyScene = openDailyScene
  openSoldiersScene = openSoldiersScene

  requestDelivery = requestDelivery
  openDelivery = openDelivery
  purchaseDelivery = purchaseDelivery

  curArmySoldiersDeliveries = curArmySoldiersDeliveries
  curArmyDailyDeliveries = curArmyDailyDeliveries
  curArmySoldiersDelivery = curArmySoldiersDelivery
  curArmyDailyDelivery = curArmyDailyDelivery
  curArmyDailyDeliveriesRefreshTime = curArmyDailyDeliveriesRefreshTime
  freeDeliveriesPurchaseTime = freeDeliveriesPurchaseTime
}
 