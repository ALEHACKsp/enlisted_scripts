local grenades = require("grenades.ui.nut")
local weaponsList = require("player_weapon_switch.nut")
local weaponBlock = require("player_cur_weapon.ui.nut")
local eventHandlersComp = require("activate_show_weapons_evt_handlers.ui.nut")
local {showWeapons, activateShowWeapons, showWeaponsBlockAlways} = require("show_weapon_list_state.nut")
local weaponListComp = { size = [0,0] valign = ALIGN_BOTTOM halign = ALIGN_RIGHT
  children = weaponsList
}

local function humanPlayerWeaponInfo(){
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    size = SIZE_TO_CONTENT
    gap = sh(0.5)
    onAttach = activateShowWeapons
    watch = showWeapons
    children = showWeaponsBlockAlways.value || showWeapons.value ? [
      weaponListComp
      weaponBlock
      grenades
      eventHandlersComp
    ] : eventHandlersComp
  }
}

return humanPlayerWeaponInfo 