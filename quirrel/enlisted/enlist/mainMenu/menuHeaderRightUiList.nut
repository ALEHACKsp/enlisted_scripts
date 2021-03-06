local {menuHeaderRightUiList, navHeaderHeight} = require("sections.nut")
local {horGap, emptyGap} = require("enlist/components/commonComps.nut")
local {navHeight} = require("mainmenu.style.nut")

navHeaderHeight(navHeight)

local armyCurrencyUi = require("enlisted/enlist/shop/armyCurrencyUi.nut")
local currenciesWidgetUi = require("enlisted/enlist/currency/currenciesWidgetUi.nut")
local premiumWidgetUi = require("enlisted/enlist/currency/premiumWidgetUi.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")

local mainMenuBtn = require("dropDownMenu.nut")

local gap = {
  size = [SIZE_TO_CONTENT, flex()]
  children = horGap
}

local monetizationBlock = @() {
  watch = monetization
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  children = monetization.value
    ? [
        premiumWidgetUi
        gap
        currenciesWidgetUi
        emptyGap
      ]
    : []
}

menuHeaderRightUiList([
  monetizationBlock,
  armyCurrencyUi,
  gap,
  mainMenuBtn
])

 