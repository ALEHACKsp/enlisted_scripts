local { setOpenShopFunctions } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { openPurchaseUrl } = require("enlisted/enlist/shop/armyShopState.nut")
local { currenciesList } = require("enlist/currency/currencies.nut")

local function initActions() {
  local actions = {}
  foreach(currency in currenciesList.value) {
    local { id, purchaseUrl = "" } = currency
    if (purchaseUrl != "")
      actions[id] <- @() openPurchaseUrl(purchaseUrl)
  }
  setOpenShopFunctions(actions)
}

initActions()
currenciesList.subscribe(@(_) initActions()) 