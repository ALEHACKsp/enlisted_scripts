local { currenciesList } = require("enlist/currency/currencies.nut")

local enlistedGold = {
  id = "EnlistedGold"
  image = @(size) "ui/skin#currency/enlisted_gold.svg:{0}:{0}:K".subst(size.tointeger())
  locId = "currency/code/EnlistedGold"
  purchaseUrl = "https://store.gaijin.net/catalog.php?category=EnlistedGold"
}

currenciesList([enlistedGold])

return {
  enlistedGold
}
 