local { openDebugWnd } = require("enlist/components/debugWnd.nut")
local { profile } = require("enlisted/enlist/meta/clientApi.nut")

local tabs = ["armies", "squads", "soldiers", "soldierPerks", "items", "soldiersLook", "cratesContent",
    "trainings", "researches", "deliveries", "armyEffects", "purchasesCount"]
  .map(@(n) { id = n, data = profile[n], maxItems = 100 })

return @() openDebugWnd({
  wndUid = "debug_profile_wnd"
  tabs = tabs
})
 