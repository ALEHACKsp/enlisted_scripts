local { byId } = require("enlist/currency/currencies.nut")

local priceWidget = function(price, currencyId) {
  local currency = byId.value?[currencyId]
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      currency == null ? null : {
        size = [::hdpx(30), ::hdpx(30)]
        rendObj = ROBJ_IMAGE
        image = ::Picture(currency.image(::hdpx(30)))
      }
      {
        rendObj = ROBJ_DTEXT
        font = Fonts.medium_text
        text = currency
          ? price
          : ::loc($"priceText/{currencyId}", { price = price }, $"{price}{currencyId}")
      }
    ]
  }
}

return {
  priceWidget = priceWidget
} 