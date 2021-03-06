local dedicated = require_optional("dedicated")
if (dedicated == null)
  return
local inventory = require("inventory/client.nut")
local {INVALID_USER_ID} = require("matching.errors")
local {EventPlayerOnLootUse} = require("lootevents")
local {logerr} = require("dagor.debug")
local { get_app_id } = require("app")

local get_item_price = ::ecs.SqQuery("get_item_price", {
  comps_ro = [
    ["inventoryItem.itemDefId", ::ecs.TYPE_INT],
    ["inventoryItem.usePrice", ::ecs.TYPE_INT],
  ]
})

local function onLootUsed(evt, eid, comp) {
  local appId = get_app_id()
  local userid = comp.userid
  if (appId <= 0 || userid == INVALID_USER_ID)
    return
  local usedItemEid = evt[0]

  get_item_price.perform(usedItemEid, function(eid, comp) {
    local itemDefId = comp["inventoryItem.itemDefId"]
    local usePrice = comp["inventoryItem.usePrice"]
    inventory.consume_items_by_itemdef(appId, userid, itemDefId, usePrice,
    function(result) {
      if (result?.error)
        logerr($"inventory consume error {result.error}")
    })
  })
}

::ecs.register_es("withdraw_used_inventory_item_es", { [EventPlayerOnLootUse] = onLootUsed}, {
  comps_ro = [
    ["userid", ::ecs.TYPE_INT64],
  ]
}, {tags="server"})
 