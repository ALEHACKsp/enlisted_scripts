local serverConfigs = require("enlisted/enlist/configs/configs.nut")

local perkList = persist("list", @() {})
serverConfigs.configs.subscribe(
  function(_) {
    local list = _?.perks?.list
    if (list == null)
      return

    perkList.clear()
    foreach(id, perk in list) {
      perk.locId <- perk?.locId ?? id
      perkList[id] <- perk
    }
})

return perkList 