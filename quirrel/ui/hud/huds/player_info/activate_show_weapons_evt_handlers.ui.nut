local {activateShowWeapons} = require("show_weapon_list_state.nut")

local eventHandlerActivate = @(...) activateShowWeapons()
local eventHandlers = ["Human.Weapon1","Human.Weapon2","Human.Weapon3",
    "Human.Weapon4","Human.Throw","Human.GrenadeNext","Human.GrenadePrev","Inventory.UseMedkit",
    "Human.WeaponNext","Human.WeaponPrev","Human.Melee", "Human.WeaponNextMain", "Human.GrenadeNext", "Human.FiringModeNext",
    "Human.WeapModToggle"
//    "Human.Reload"
  ].map(@(v) [v,eventHandlerActivate]).totable()

return {
  eventHandlers = eventHandlers
}
 