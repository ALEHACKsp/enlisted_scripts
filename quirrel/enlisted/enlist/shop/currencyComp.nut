local msgbox = require("enlist/components/msgbox.nut")
local { txt } = require("enlisted/enlist/components/defcomps.nut")
local {
  bigGap, smallPadding, defTxtColor, activeTxtColor
} = require("enlisted/enlist/viewConst.nut")
local { Purchase } = require("enlist/components/textButton.nut")
local textButtonTextCtor = require("enlist/components/textButtonTextCtor.nut")
local tooltipBox = require("ui/style/tooltipBox.nut")
local cursors = require("ui/style/cursors.nut")

local function mkCurrencyTooltip(currencyTpl) {
  local descText = ::loc($"items/{currencyTpl}/desc", "")
  return tooltipBox({
    flow = FLOW_VERTICAL
    gap = bigGap
    children = [
      {
        rendObj = ROBJ_DTEXT
        minWidth = ::hdpx(250)
        text = ::loc($"items/{currencyTpl}")
        color = activeTxtColor
        font = Fonts.small_text
      }
      descText == "" ? null : {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        text = descText
        color = defTxtColor
        font = Fonts.small_text
      }
    ]
  })
}

local mkCurrencyImage = @(currencyTpl, size = ::hdpx(30)) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = ::Picture("!ui/uiskin/currency/{0}.svg:{1}:{1}:K".subst(currencyTpl, size.tointeger()))
  fallbackImage = ::Picture("!ui/uiskin/currency/weapon_order.svg:{0}:{0}:K".subst(size.tointeger()))
}

local function mkItemCurrency(currencyTpl, count, onClick = null, hasAnim = false, keySuffix = "") {
  local trigger = $"blink_{currencyTpl}"
  local stateFlags = Watched(0)
  return @() {
    key = $"currency_{currencyTpl}{hasAnim}{keySuffix}"
    size = [SIZE_TO_CONTENT, flex()]
    minHeight = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    children = [
      mkCurrencyImage(currencyTpl).__update(hasAnim
        ? {
            transform = { pivot = [0.5, 0.5] }
            animations = [
              { prop = AnimProp.scale, easing = InOutCubic, trigger,
                from = [1,1], to = [1.3,1.3], duration = 0.2 }
              { prop = AnimProp.scale, easing = InOutCubic, trigger,
                from = [1.3,1.3], to = [1.3,1.3], duration = 1.2, delay = 0.2 }
              { prop = AnimProp.scale, easing = InOutCubic, trigger,
                from = [1.3,1.3], to = [1,1], duration = 0.2, delay = 1.4 }
              { prop = AnimProp.rotate, easing = Discrete8, trigger,
                from = 0, to = 30, duration = 0.25, delay = 0.4 }
              { prop = AnimProp.rotate, easing = Discrete8, trigger,
                from = 30, to = -30, duration = 0.45, delay = 0.6 }
              { prop = AnimProp.rotate, easing = Discrete8, trigger,
                from = -30, to = 0, duration = 0.25, delay = 1 }
            ]
          }
        : {})
      {
        rendObj = ROBJ_DTEXT
        font = Fonts.medium_text
        color = stateFlags.value & S_HOVER ? activeTxtColor : defTxtColor
        text = count
      }
    ]
  }.__update(onClick != null
    ? {
        watch = stateFlags
        behavior = Behaviors.Button
        skipDirPadNav = true
        onClick = onClick
        onHover = @(on) cursors.tooltip.state(on ? mkCurrencyTooltip(currencyTpl) : null)
        onElemState = @(sf) stateFlags(sf)
      }
    : {}
  )
}

local mkCurrencyButton = @(text, currency, count = null, cb = null, style = {})
  Purchase(text, cb, style.__merge({
    textCtor = @(textField, params, handler, group, sf) textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = textField?.margin
      children = [
        textField.__merge({ margin = [0, ::hdpx(10), 0, 0] })
        mkCurrencyImage(currency)
        "" ==  (count ?? "") ? null : {
          rendObj = ROBJ_DTEXT
          font = Fonts.medium_text
          color = defTxtColor
          text = count
        }
      ]
    }, params, handler, group, sf)
  }))

local mkLogisticsPromoMsgbox = @(currencies) msgbox.showMessageWithContent({
  content = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = sh(4)
    children = [
      txt(::loc("menu/enlistedShop")).__update({
        font = Fonts.big_text
        color = activeTxtColor
      })
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        color = defTxtColor
        text = ::loc("menu/enlistedShopDesc")
      }
      {
        flow = FLOW_VERTICAL
        gap = bigGap
        children = currencies.keys().map(@(currencyTpl) {
          gap = bigGap
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          children = [
            mkCurrencyImage(currencyTpl, ::hdpx(70))
            {
              size = [::hdpx(300), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = smallPadding
              children = [
                txt(::loc($"items/{currencyTpl}")).__update({
                  font = Fonts.small_text
                  color = activeTxtColor
                })
                {
                  rendObj = ROBJ_TEXTAREA
                  behavior = Behaviors.TextArea
                  size = [flex(), SIZE_TO_CONTENT]
                  text = ::loc($"items/{currencyTpl}/desc", "")
                  color = defTxtColor
                  font = Fonts.small_text
                }
              ]
            }
          ]
        })
      }
    ]
  }
  buttons = [{
    text = ::loc("OK"), isCurrent = true, isCancel = true
  }]
})

return {
  mkCurrencyTooltip
  mkCurrencyImage
  mkCurrencyButton = ::kwarg(mkCurrencyButton)
  mkItemCurrency
  mkLogisticsPromoMsgbox
}
 