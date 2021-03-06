local {btnTranspTextColor, TextActive} = require("ui/style/colors.nut")
local currencies = require("enlist/currency/currencies.nut")
local { openPurchaseUrl } = require("enlisted/enlist/shop/armyShopState.nut")
local { gap } = require("enlisted/enlist/viewConst.nut")
local { mkCurrency } = require("currenciesComp.nut")
local platform = require("globals/platform.nut")

local function currencyBalance(currency) {
  local stateFlags = Watched(0)
  return @() {
    watch = [currencies.balance, stateFlags]
    size = [SIZE_TO_CONTENT, flex()]
    valign = ALIGN_CENTER
    behavior = platform.is_pc ? Behaviors.Button : null
    onElemState = @(sf) stateFlags(sf)
    onClick = (currency?.purchaseUrl ?? "") != "" ? @() openPurchaseUrl(currency.purchaseUrl) : null

    children = mkCurrency(currency,
      currencies.balance.value?[currency.id],
      btnTranspTextColor(stateFlags.value, false, TextActive))
  }
}

local function currenciesWidget() {
  local visibleCurrencies = currencies.sorted.value.filter(@(currency) currency?.visible.value ?? true)
  return {
    watch = currencies.sorted
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_HORIZONTAL
    gap = gap
    children = visibleCurrencies.map(currencyBalance)
  }
}

return currenciesWidget
 