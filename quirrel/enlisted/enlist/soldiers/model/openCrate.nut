local client = require("enlisted/enlist/meta/clientApi.nut")


local function dropAfterBattleCrate(armyId, dropCrateId = null, cb = null) {
  client.drop_items(armyId, dropCrateId)
}

return {
  dropAfterBattleCrate = dropAfterBattleCrate
}
 