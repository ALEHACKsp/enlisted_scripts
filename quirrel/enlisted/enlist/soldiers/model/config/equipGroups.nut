local equipGroups = [
  {
    name = "weapons"
    locId = "inventory/Weapons"
    slots = ["primary", "secondary", "side", "grenade", "melee", "radio", "mortar", "building_tool"]
  }
  {
    name = "equipment"
    locId = "inventory/Equipment"
    slots = ["backpack", "armor"]
  }
  {
    name = "inventory"
    locId = "inventory/Inventory"
    slots = ["inventory"]
  }
]

local slotTypeToEquipGroup = {}
foreach(idx, eg in equipGroups) {
  eg.idx <- idx
  foreach(slot in eg.slots) {
    assert(!(slot in slotTypeToEquipGroup), $"Duplicate slot {slot}")
    slotTypeToEquipGroup[slot] <- eg
  }
}

return {
  equipGroups = equipGroups
  slotTypeToEquipGroup = slotTypeToEquipGroup
} 