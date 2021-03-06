local httpRequest = require("httpRequest.nut")
local userInfo = require("enlist/state/userInfo.nut")

local purchased = Watched({})

local refresh = function() {
  if (!purchased.value.len() || !userInfo.value)
    return

  httpRequest.requestData("https://purch.gaijinent.com/check_purchase.php",
    httpRequest.createGuidsRequestParams(purchased.value.keys()),
    function(data) {
      local isChanged = false
      foreach(guid, amount in data?.items ?? {})
        if (purchased.value?[guid] != amount) {
          purchased.value[guid] <- amount
          isChanged = true
        }
      if (isChanged)
        purchased.trigger()
    })
}

local function addGuids(guids) {
  local wasTotal = purchased.value.len()
  foreach(guid in guids)
    if (!(guid in purchased.value))
      purchased.value[guid] <- 0
  if (wasTotal != purchased.value.len())
    refresh()
}

userInfo.subscribe(function(val) {
  if (val)
    refresh()
  else
    purchased.value.clear()
})

return {
  purchased = purchased
  addGuids = addGuids
  refreshPurchased = refresh
} 