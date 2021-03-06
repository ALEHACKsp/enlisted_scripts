local {selfHealMedkits} = require("ui/hud/state/total_medkits.nut")
local {weaponsList, fastThrowExclusive} = require("ui/hud/state/hero_state.nut")
local {showWeaponList} = require("show_weapon_list_state.nut")
local weaponWidget = require("player_weapon_widget.nut")
local getWeaponHotkeyWidget = require("player_weapon_hotkey.nut")

local weaponItemsWatches = [weaponsList, selfHealMedkits, fastThrowExclusive]

local function weaponItems() {
  local children = []
  if (weaponsList.value && showWeaponList.value) {
    local weaponHotkeys = array(4).map(@(val, i) "Human.Weapon{0}".subst(i+1))
    weaponHotkeys.append(fastThrowExclusive.value ? "Human.Throw" : "Human.GrenadeNext")
    foreach (idx, weapon in weaponsList.value) {
      local hotkey = getWeaponHotkeyWidget(weaponHotkeys[idx],  weapon?.name!="")
      children.append(weaponWidget({ weapon = weapon, hotkey = hotkey }))
    }
    if (selfHealMedkits.value > 0 ) {
      local medkits = {name=::loc("hud/medkits"), instant = true, curAmmo = selfHealMedkits.value}
      local hotkey = getWeaponHotkeyWidget("Inventory.UseMedkit", true)
      children.append(weaponWidget({ weapon = medkits, hotkey = hotkey }))
    }
  }

  return {
    size = [0,0]
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    gap = hdpx(4)
    watch = weaponItemsWatches
    children = children
  }
}


local function weaponsListComp() {
  return {
    size = SIZE_TO_CONTENT
    watch = [showWeaponList]
    children = weaponItems
  }
}


return weaponsListComp
 