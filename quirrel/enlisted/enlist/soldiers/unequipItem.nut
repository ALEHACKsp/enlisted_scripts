local { getLinksByType } = require("enlisted/enlist/meta/metalink.nut")
local { getDemandingSlots, getDemandingSlotsInfo
} = require("enlisted/enlist/soldiers/model/state.nut")
local { equipItem } = require("enlisted/enlist/soldiers/model/itemActions.nut")
local popupsState = require("enlist/popup/popupsState.nut")

local function unequip(slotType, slotId, ownerGuid) {
  local listByDemands = getDemandingSlots(ownerGuid, slotType)
  if (listByDemands.len() > 0) {
    local equippedCount = listByDemands.filter(@(item) item != null).len()
    if (equippedCount <= 1) {
      local demandingInfo = getDemandingSlotsInfo(ownerGuid, slotType)
      if ((demandingInfo ?? "").len() > 0)
        return popupsState.addPopup({
          id = "unequip_item_error"
          text = demandingInfo
          styleName = "error"
        })
    }
  }
  equipItem(null, slotType, slotId, ownerGuid)
}

local function unequipBySlot(slotData) {
  local { slotType, slotId, ownerGuid } = slotData
  unequip(slotType, slotId, ownerGuid)
}

local function unequipItem(data) {
  local { item = null, slotType = null, slotId = null, soldierGuid = null } = data
  if (item == null || slotType == null)
    return
  local ownerGuid = soldierGuid ?? getLinksByType(item, slotType)?[0]
  if (!ownerGuid)
    return
  unequip(slotType, slotId, ownerGuid)
}

return {
  unequip
  unequipBySlot
  unequipItem
} 