local {
  bigGap, bigPadding, defBgColor, defTxtColor, activeTxtColor
} = require("enlisted/enlist/viewConst.nut")
local { premiumImage } = require("premiumComp.nut")
local textButton = require("enlist/components/textButton.nut")
local premiumWnd = require("premiumWnd.nut")
local { hasPremium } = require("premium.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")

local sendOpenPremium = @(srcWindow, srcComponent)
  sendBigQueryUIEvent("open_premium_window", srcWindow, srcComponent)

local mkPromoLarge = @(srcWindow = null, srcComponent = null) function() {
  local res = { watch = hasPremium }
  if (hasPremium.value)
    return res
  return res.__update({
    rendObj = ROBJ_WORLD_BLUR_PANEL
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    gap = bigGap
    padding = bigPadding
    flow = FLOW_HORIZONTAL
    color = defBgColor
    children = [
      premiumImage(::hdpx(55))
      {
        rendObj = ROBJ_TEXTAREA
        maxWidth = ::hdpx(600)
        behavior = Behaviors.TextArea
        font = Fonts.medium_text
        text = ::loc("premium/buyForExperience")
        color = activeTxtColor
      }
      textButton.PrimaryFlat(::loc("btn/buy"),
        function() {
          premiumWnd()
          sendOpenPremium(srcWindow, srcComponent)
        },
        {
          hotkeys = [[ "^J:X", { description = {skip=true}} ]]
        })
    ]
  })
}

local mkPromoSmall = @(locId, override = null, srcWindow = null, srcComponent = null) function() {
  local res = { watch = hasPremium }
  if (hasPremium.value)
    return res
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    gap = bigGap
    flow = FLOW_HORIZONTAL
    children = [
      premiumImage(::hdpx(35))
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        font = Fonts.tiny_text
        text = ::loc(locId)
        color = defTxtColor
      }
      textButton.FAButton("shopping-cart", function() {
        premiumWnd()
        sendOpenPremium(srcWindow, srcComponent)
      }, { borderWidth = 0, borderRadius = 0 })
    ]
  }).__update(override ?? {})
}

return {
  promoLarge = mkPromoLarge
  promoSmall = mkPromoSmall
} 