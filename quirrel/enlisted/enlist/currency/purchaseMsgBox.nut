local checkbox = require("ui/components/checkbox.nut")
local msgbox = require("enlist/components/msgbox.nut")
local { byId, balance } = require("enlist/currency/currencies.nut")
local { dontShowToday, setDontShowTodayByKey } = require("enlist/options/dontShowAgain.nut")
local colorize = require("enlist/colorize.nut")
local colors = require("ui/style/colors.nut")
local textButtonTextCtor = require("enlist/components/textButtonTextCtor.nut")
local { priceWidget } = require("enlist/components/priceWidget.nut")
local { makeVertScroll, thinStyle } = require("ui/components/scrollbar.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")

local offset = sh(3)
local currencySize = hdpx(29)
local openShopByCurrencyId = {}

local mkItemDescription = @(description) makeVertScroll({
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    font = Fonts.medium_text
    text = description
  }
  {
    size = [flex(), SIZE_TO_CONTENT]
    maxHeight = ::hdpx(300)
    styling = thinStyle
  })

local currencyImage = @(currency) currency
  ? {
      size = [currencySize, currencySize]
      rendObj = ROBJ_IMAGE
      image = ::Picture(currency.image(currencySize))
    }
  : null

local function mkItemCostInfo(price, currencyId) {
  local currency = byId.value?[currencyId]
  return {
    flow = FLOW_HORIZONTAL
    children = [
      {
        rendObj = ROBJ_DTEXT
        font = Fonts.big_text
        text = "{0} ".subst(::loc("shop/willCostYou"))
      }
      currencyImage(currency)
      {
        rendObj = ROBJ_DTEXT
        font = Fonts.big_text
        text = currency || ::type(price) == "string"
          ? price
          : ::loc($"priceText/{currencyId}", { price = price }, $"{price}{currencyId}")
      }
    ]
  }
}

local function buyCurrencyText(currency, sf) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
    gap = currencyImage(currency)
    children = ::loc("btn/buyCurrency").split("{currency}").map(@(text) {
      rendObj = ROBJ_DTEXT
      color = colors.textColor(sf, false, colors.TextActive)
      font = Fonts.big_text
      text = text
    })
  }
}

local function notEnoughMoneyInfo(price, currencyId) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_DTEXT
        color = colors.HighlightFailure
        font = Fonts.big_text
        text = ::loc("shop/notEnoughCurrency", {
          priceDiff = price - (balance.value?[currencyId] ?? 0)
        })
      }
      currencyImage(byId.value?[currencyId])
    ]
  }
}

local function show(price, currencyId, purchase, title = "", productView = null, description = null,
  purchaseCurrency = null, dontShowMeTodayId = null, srcWindow = null, srcComponent = null, alwaysShowCancel = false
) {
  local bqBuyCurrency = @() sendBigQueryUIEvent("action_buy_currency", srcWindow, srcComponent)
  local currency = byId.value?[currencyId]
  local notEnoughMoney = @(needMoney) currency != null
    && ((balance.value?[currencyId] ?? 0) < needMoney)

  if (!(price instanceof ::Watched))
    price = ::Watched(price)

  local buttons = notEnoughMoney(price.value) ? []
    : [{
        text = ::loc("btn/buy")
        action = function() {
          purchase()
          bqBuyCurrency()
        }
        customStyle = {
          hotkeys = [[ "^J:Y | Enter", { description = {skip = true}} ]]
        }
      }]

  local dontShowCheckbox = null
  if (dontShowMeTodayId != null && !notEnoughMoney) {
    local dontShowMeToday = ::Computed(@() dontShowToday.value?[dontShowMeTodayId] ?? false)
    if (dontShowMeToday.value) {
      purchase()
      bqBuyCurrency()
      return
    }
    dontShowCheckbox = checkbox(dontShowMeToday, ::loc("dontShowMeAgainToday"),
      { setValue = @(v) setDontShowTodayByKey(dontShowMeTodayId, v) })
  }

  if (notEnoughMoney(price.value)) {
    purchaseCurrency = purchaseCurrency ?? openShopByCurrencyId?[currencyId]
    if (purchaseCurrency != null)
      buttons.append({
        customStyle = {
          textCtor = function(textComp, params, handler, group, sf) {
            textComp = buyCurrencyText(currency, sf)
            params = { font = Fonts.big_text }
            return textButtonTextCtor(textComp, params, handler, group, sf)
          }
        },
        action = function() {
          purchaseCurrency()
          sendBigQueryUIEvent("event_low_currency", srcWindow, srcComponent)
        }
      })
    if (alwaysShowCancel || purchaseCurrency == null)
      buttons.append({ text = ::loc("Cancel") })
  }

  local params = {
    text = colorize(colors.MsgMarkedText, title)
    children = {
      size = [sh(80), SIZE_TO_CONTENT]
      margin = productView != null ? null : [offset, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = offset
      children = [
        productView
        description ? mkItemDescription(description) : null
        @() {
          watch = price
          halign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          children = [
            mkItemCostInfo(price.value, currencyId)
            notEnoughMoney(price.value) ? notEnoughMoneyInfo(price.value, currencyId)
              : dontShowCheckbox
          ]
        }
      ]
    }
    topPanel = currencyId in byId.value
      ? priceWidget(balance.value?[currencyId] ?? ::loc("lb/notAvailable"), currencyId)
          .__update({
            size = [SIZE_TO_CONTENT, flex()]
            gap = ::hdpx(10)
          })
      : null
    buttons = buttons
  }

  msgbox.showWithCloseButton(params)
  sendBigQueryUIEvent("open_buy_currency_window", srcWindow, srcComponent)
}

return {
  purchaseMsgBox = ::kwarg(show)
  setOpenShopFunctions = @(list) openShopByCurrencyId.__update(list)
} 