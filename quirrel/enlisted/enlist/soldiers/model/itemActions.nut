local { disassemble_item, upgrade_item, equip_item, swap_items } = require("enlisted/enlist/meta/clientApi.nut")

local isItemActionInProgress = ::Watched(false)

local mkActionCb = @(cb) function(res) {
  isItemActionInProgress(false)
  cb?(res)
}

local function disassembleItem(armyId, itemGuid, cb = null) {
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  disassemble_item(armyId, itemGuid, mkActionCb(cb))
}

local function upgradeItem(armyId, itemGuid, spendItemGuids, cb = null) {
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  upgrade_item(armyId, itemGuid, spendItemGuids, mkActionCb(cb))
}

local function equipItem(itemGuid, slotType, slotId, targetGuid) {
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  equip_item(targetGuid, itemGuid, slotType, slotId, mkActionCb(null))
}

local function swapItems(soldierGuid1, slotType1, slotId1, soldierGuid2, slotType2, slotId2){
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  swap_items(soldierGuid1, slotType1, slotId1, soldierGuid2, slotType2, slotId2, mkActionCb(null))
}

return {
  isItemActionInProgress = isItemActionInProgress

  disassembleItem = disassembleItem
  upgradeItem = upgradeItem
  equipItem = equipItem
  swapItems = swapItems
} 