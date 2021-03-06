local { bigPadding } = require("enlisted/enlist/viewConst.nut")
local { mkItemCurrency } = require("currencyComp.nut")
local { curArmyCurrency } = require("armyShopState.nut")
local { setCurSection } = require("enlisted/enlist/mainMenu/sectionsState.nut")

local openShop = @() setCurSection("SHOP")

local function mkArmyCurrency(armyCurrency) {
  local res = []
  foreach(currencyTpl, count in armyCurrency)
    res.append(mkItemCurrency(currencyTpl, count, openShop, true))
  return res
}

local currencyUi = @() {
  watch = curArmyCurrency
  size = [SIZE_TO_CONTENT, flex()]
  minHeight = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = mkArmyCurrency(curArmyCurrency.value)
}

return currencyUi
 