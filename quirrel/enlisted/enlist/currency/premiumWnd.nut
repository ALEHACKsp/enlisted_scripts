local modalWindows = require("daRg/components/modalWindows.nut")
local textButton = require("enlist/components/textButton.nut")
local JB = require("ui/control/gui_buttons.nut")
local msgbox = require("enlist/components/msgbox.nut")
local { hasPremium } = require("premium.nut")
local { curCampaign } = require("enlisted/enlist/soldiers/model/state.nut")
local { shopItems } = require("enlisted/enlist/shop/armyShopState.nut")
local buyShopItem = require("enlisted/enlist/shop/buyShopItem.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")

local { txt } = require("enlisted/enlist/components/defcomps.nut")
local { textarea } = require("enlist/components/text.nut")
local { defTxtColor, activeTxtColor, soldierExpColor, defBgColor, darkBgColor, gap } = require("enlisted/enlist/viewConst.nut")
local { premiumActiveInfo, premiumImage } = require("premiumComp.nut")
local mkShopItemPrice = require("enlisted/enlist/shop/mkShopItemPrice.nut")
local mkTextRow = require("daRg/helpers/mkTextRow.nut")

const WND_UID = "premiumWindow"

local close = @() modalWindows.remove(WND_UID)

local premiumProduct = ::Computed(function() {
  local list = shopItems.value.filter(@(i) (i?.premiumDays ?? 0) > 0)
  if (list.len() <= 1)
    return list.values()?[0]

  return list.reduce(function(res, item) {
    if (res == null)
      return item
    local itemPrice = item.curShopItemPrice.price
    local resPrice = res.curShopItemPrice.price
    if (itemPrice > 0 && (resPrice <= 0 || resPrice > itemPrice))
      return item
    if (resPrice > 0)
      return res
    itemPrice = item?.shop_price ?? 0
    resPrice = res?.shop_price ?? 0
    return (itemPrice > 0 && (resPrice <= 0 || resPrice > itemPrice)) ? item : res
  })
})

local function onPurchase() {
  if (premiumProduct.value == null)
    msgbox.show({ text = ::loc("willBeAvailableSoon") })
  else {
    buyShopItem(premiumProduct.value)
    sendBigQueryUIEvent("action_buy_premium", "premium_promo")
  }
}

local premiumButtons = @() {
  watch = hasPremium
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  children = [
    hasPremium.value
      ? null
      : textButton.PrimaryFlat(::loc("btn/buy"),
          onPurchase,
          { hotkeys = [["^Space | Enter | J:X"]]})
    textButton.Flat(::loc("Close"), close, { hotkeys = [["^Esc | {0}".subst(JB.B)]] })
  ]
}

local backImage = {
  size = [pw(100), pw(75)]
  vplace = ALIGN_TOP
  children = @() {
    watch = curCampaign
    rendObj = ROBJ_IMAGE
    size = flex()
    keepAspect = true
    imageValign = ALIGN_TOP
    image = ::Picture($"ui/gameImage/premium_bg.jpg")
  }
}

local function premiumPrice() {
  local res = { watch = premiumProduct }
  local shopItem = premiumProduct.value
  if (shopItem == null)
    return res

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = mkTextRow(::loc("premiumPrice", { days = shopItem.premiumDays }),
      @(text) { rendObj = ROBJ_DTEXT, text = text, color = defTxtColor, font = Fonts.medium_text },
      { ["{price}"] = mkShopItemPrice(shopItem, {}, false) }) //warning disable: -forgot-subst)
  }
}

local promoDescription = {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  gap = sh(2)
  padding = sh(2)
  color = darkBgColor
  children = [
    txt({ text = ::loc("premium/header"), font = Fonts.medium_text })
    textarea(::loc("premium/enlistedInfo")).__update({
      font = Fonts.medium_text
      color = soldierExpColor
    })
    premiumPrice
  ]
}

local premiumInfoBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_SOLID
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = gap
      halign = ALIGN_CENTER
      padding = sh(2)
      color = Color(0, 0, 0, 255)
      children = [
        premiumImage(hdpx(70))
        {
          flow = FLOW_VERTICAL
          gap = gap
          children = [
            txt({
              text = ::loc("premium/title")
              font = Fonts.big_text
              color = activeTxtColor
            })
            premiumActiveInfo({ font = Fonts.medium_text })
          ]
        }
      ]
    }
    {
      size = [flex(), sh(50)]
      clipChildren = true
      children = [
        backImage
        promoDescription
      ]
    }
    {
      rendObj = ROBJ_SOLID
      size = [flex(), SIZE_TO_CONTENT]
      color = defBgColor
      children = premiumButtons
    }
  ]
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
    { prop = AnimProp.translate, from =[hdpx(150), 0], to = [0, 0], duration = 0.2, play = true, easing = OutQuad }
  ]
}

local function open() {
  modalWindows.add({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = {
      size = [sh(100), SIZE_TO_CONTENT]
      children = premiumInfoBlock
    }
  })
}
return open
 