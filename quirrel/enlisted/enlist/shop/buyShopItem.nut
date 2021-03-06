local msgbox = require("enlist/components/msgbox.nut")
local { curCampItems } = require("enlisted/enlist/soldiers/model/state.nut")
local { purchaseMsgBox } = require("enlisted/enlist/currency/purchaseMsgBox.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")


local {
  getPayItemsData, buyShopItem, barterShopItem, buyItemByGuid,
  getBuyRequirementError
} = require("armyShopState.nut")


local function buyItem(shopItem, productView = null, activatePremiumBttn = null) {
  local requiredInfo = getBuyRequirementError(shopItem)
  if (requiredInfo != null) {
    local buttons = [{ text = ::loc("Ok"), isCancel = true }]
    if (requiredInfo.solvableByPremium && monetization.value && activatePremiumBttn!=null)
      buttons.append(activatePremiumBttn)
    if (requiredInfo?.resolveCb != null)
      buttons.append({ text = requiredInfo.resolveText,
        action = requiredInfo.resolveCb,
        isCurrent = true })
    return msgbox.show({ text = requiredInfo.text, buttons = buttons })
  }

  local payData = getPayItemsData(shopItem, curCampItems.value)
  if (payData != null) {
    barterShopItem(shopItem, payData)
    return
  }

  local { price, currencyId } = shopItem.curShopItemPrice
  if (monetization.value && price > 0) {
    purchaseMsgBox({
      price = price
      currencyId = currencyId
      title = ::loc(shopItem.nameLocId)
      productView = productView
      purchase = @() buyShopItem(shopItem, currencyId, price)
      srcComponent = "buy_shop_item"
    })
    return
  }

  if ((shopItem?.purchaseGuid ?? "") != "")
    if (buyItemByGuid(shopItem.purchaseGuid))
      return

  msgbox.show({ text = ::loc("shop/noItemsToPay") })
  return
}

return buyItem 