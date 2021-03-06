local textButtonTextCtor = require("enlist/components/textButtonTextCtor.nut")
local { TextHover, TextNormal } = require("daRg/components/textButton.style.nut")
local { Purchase } = require("enlist/components/textButton.nut")
local { gap } = require("enlisted/enlist/viewConst.nut")
local { TextActive } = require("ui/style/colors.nut")

local mkCurrencyImg = @(currency, cSize) {
  size = [hdpx(cSize), hdpx(cSize)]
  rendObj = ROBJ_IMAGE
  image = ::Picture(currency.image(hdpx(cSize)))
}

local mkCurrencyCount = @(count, color = TextActive) {
  rendObj = ROBJ_DTEXT
  text = count
  font = Fonts.medium_text
  color = color
}

local mkCurrency = @(currency, balance, txtColor = TextActive) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = gap
  children = [
    mkCurrencyImg(currency, 30)
    balance == null
      ? {
          rendObj = ROBJ_DTEXT
          text = ::loc("lb/notAvailable") // FIXME bad practice to use a foreign name
          font = Fonts.small_text
          color = txtColor
        }
      : mkCurrencyCount(balance, txtColor)
  ]
}

local currencyBtn = @(btnText, currency, price = null, cb = @() null, style = {})
  Purchase(btnText, cb, style.__merge({
    textCtor = @(textField, params, handler, group, sf) textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = textField?.margin
      children = [
        textField.__merge({ margin = [0, ::hdpx(10), 0, 0] })
        mkCurrencyImg(currency, 30)
        "" ==  (price ?? "") ? null : mkCurrencyCount(price, sf & S_HOVER ? TextHover : TextNormal)
      ]
    }, params, handler, group, sf)
  }))

return {
  mkCurrency
  currencyBtn = ::kwarg(currencyBtn)
  mkCurrencyImg
  mkCurrencyCount
}
 