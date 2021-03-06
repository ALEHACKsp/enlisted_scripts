local { bigPadding } = require("enlisted/enlist/viewConst.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { currenciesList } = require("enlist/currency/currencies.nut")
local { curCampItemsCount } = require("enlisted/enlist/soldiers/model/state.nut")
local { mkItemCurrency } = require("currencyComp.nut")
local { mkCurrency } = require("enlisted/enlist/currency/currenciesComp.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")

local mkShopItemPrice = @(shopItem, bgParams = {}, needPriceText = true) function() {
  local itemsCount = curCampItemsCount.value
  local isEnough = shopItem.curItemCost
    .findindex(@(price, tpl) (itemsCount?[tpl] ?? 0) < price) == null

  local children = []
  foreach (itemTpl, value in shopItem.curItemCost)
    children.append(mkItemCurrency(itemTpl, value, null, isEnough, shopItem.guid))

  if (monetization.value && (!isEnough || shopItem.curItemCost.len() == 0)) {
    local price = shopItem.curShopItemPrice.price
    local currency = currenciesList.value
      .findvalue(@(c) c.id = shopItem.curShopItemPrice.currencyId)
    if (currency != null && price > 0) {
      if (children.len() > 0)
        children.append(txt({ text = ::loc("mainmenu/or"), font = Fonts.medium_text }))
      children.append(mkCurrency(currency, price))
    }
  }

  if (children.len() == 0) {
    local { shop_price_curr = "", shop_price = 0 } = shopItem
    children.append(txt({
      text = ::loc($"priceText/{shop_price_curr}", { price = shop_price }, $"{shop_price}{shop_price_curr}")
      font = Fonts.medium_text
    }))
  }

  if (needPriceText && children.len() > 0)
    children.insert(0, txt({ text = ::loc("price"), font = Fonts.medium_text }))

  return {
    watch = [curCampItemsCount, monetization]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }.__update(bgParams)
}

return mkShopItemPrice 