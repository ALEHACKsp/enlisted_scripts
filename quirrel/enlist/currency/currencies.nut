local {isEqual} = require("std/underscore.nut")
local userInfo = require("enlist/state/userInfo.nut")
local currenciesList = persist("currenciesList", @() Watched([]))
local matchingNotifications = require("enlist/state/matchingNotifications.nut")

local balance = persist("currencyBalance", @() Watched({}))
local expiring = persist("expiring", @() ::Watched({}))
local purchases = persist("purchases", @() Watched({}))

userInfo.subscribe(function(v) {
  if (v)
    return
  balance({})
  purchases({})
})

local function mkCurrency(config){
  local id = config.id
  return {
    id = id
    image = @(size) null
    locId = $"currency/code/{id}"
  }.__update(config)
}
local sorted = ::Computed(function(){
  return currenciesList.value.map(mkCurrency)
})
local byId = ::Computed(function(){
  local res = {}
  foreach (config in currenciesList.value){
    local currency = mkCurrency(config)
    local id = currency.id
    assert(!(id in res), $"Currency: duplicate currency id {id}")
    res[id] <- currency
  }
  return res
})

local notifications = {
  update_balance = function(ev) {
    if (typeof(ev?.balance) != "table") {
      log("Got currency notification without balance table")
      return
    }
    local newBalance = clone balance.value
    local newExpiring = clone expiring.value
    foreach (k, v in ev.balance) {
      newBalance[k] <- v?.value
      newExpiring[k] <- v?.expiring
    }
    if (!isEqual(newBalance, balance.value))
      balance(newBalance)
    if (!isEqual(newExpiring, expiring.value))
      expiring(newExpiring)
  }

  function update_purchasable_list(ev) {
    local newPurch = ev?.purchases ?? {}
    if (!isEqual(newPurch, purchases.value))
      purchases(newPurch)
  }
}

local function processNotification(ev) {
  local handler = notifications?[ev?.func]
  if (handler)
    handler(ev)
  else
    log("Unexpected currency notification type:", (ev?.func ?? "null"))
}

matchingNotifications.subscribe("currency", processNotification)


console.register_command(@() console_print(balance.value), "currencies.balance")
console.register_command(@(key, val) balance(@(data) data[key] <- val), "currencies.set")

local showRealCurrencyPrices = persist("showRealCurrencyPrices", @() Watched(true))

return {
  byId = byId
  sorted = sorted
  balance = balance
  expiring = expiring
  purchases = purchases
  currenciesList = currenciesList
  processNotification = processNotification
  showRealCurrencyPrices = showRealCurrencyPrices
}
 