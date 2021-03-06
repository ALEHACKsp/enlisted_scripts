local httpRequest = require("httpRequest.nut")
local userInfo = require("enlist/state/userInfo.nut")
local purchases = require("purchases.nut")

local goodsInfo = persist("goodsInfo", @() Watched({})) //purchases info from online shop by guids

local isGoodsRequested = Watched(false)
local marketIds = null
local function requestGoodsInfo(...) {
  local guids = marketIds.value.map(@(val) val.guid)
  purchases.addGuids(guids)

  if (!userInfo.value)
    return

  guids = guids.filter(@(guid) !(guid in goodsInfo.value))
  if (!guids.len())
    return

  foreach(guid in guids)
    goodsInfo.value[guid] <- null

  isGoodsRequested(true)
  httpRequest.requestData(
    "https://api.gaijinent.com/item_info.php",
    httpRequest.createGuidsRequestParams(guids),
    function(data) {
      isGoodsRequested(false)
      local list = data?.items
      if (typeof list != "table" || !list.len())
        return
      goodsInfo.update(@(value) value.__update(list))
    },
    function() { isGoodsRequested(false) }
  )
}

userInfo.subscribe(requestGoodsInfo)

return purchases.__merge({
  goodsInfo = goodsInfo
  collectMarketIds = @(value) marketIds = value
  requestGoodsInfo = requestGoodsInfo
  isGoodsRequested = isGoodsRequested
}) 