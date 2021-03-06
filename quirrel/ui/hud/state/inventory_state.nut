local {drop_gear_from_slot, drop_item, remove_item_from_weap_to_inventory, drop_weap_from_slot, pickup_item_entity} = require("humaninv")

local focusedData = ::Watched(null)
local isShiftPressed = ::Watched(false)

local function mkTryDrop(item){
  if (!(item?.canDrop))
    return null
  return item?.currentEquipmentSlotName
        ? @() drop_gear_from_slot(item.currentEquipmentSlotName)
        : (item?.eid)
          ? @() drop_item(item.eid)
          : (item?.currentWeapModSlotName!=null && item?.currentWeaponSlotName!=null)
            ? @() remove_item_from_weap_to_inventory(item.currentWeaponSlotName, item.currentWeapModSlotName)
            : (item?.currentWeaponSlotName && item.currentWeaponSlotName != "melee")
             ? @() drop_weap_from_slot(item.currentWeaponSlotName)
             : null
}

local function doForAllEidsWhenShift(item, action) {
  if (isShiftPressed.value && ("eids" in item))
    item.eids.each(action)
  else
    action(item.eid)
}

return {
  draggedData = ::Watched(null)
  focusedData = focusedData
  isShiftPressed = isShiftPressed
  requestData = ::Watched(null)
  requestItemData = ::Watched(null)
  focusedItem = ::Computed(function() {
    local item = focusedData.value
    if (item==null)
      return null
    local tryTake = (item?.canTake && item?.eid) ? @() pickup_item_entity(item.eid)  : null
    local tryDrop = mkTryDrop(item)
    local tryUse = item?.onUse
    return item.__merge({use = tryUse, drop = tryDrop, take=tryTake})
  })
  doForAllEidsWhenShift = doForAllEidsWhenShift
}
 