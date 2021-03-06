local {request_suicide} = require("dm")
local {get_controlled_hero} = require("globals/common_queries.nut")
local {drop_gear_from_slot, drop_weap_from_slot, remove_item_from_weap_to_inventory} = require("humaninv")
local {request_weapon_reload, choose_weapon, unload_weapon_ammo_to_inventory} = require("human_weap")

console.register_command(function() {request_suicide()},
  "player.kill")

console.register_command(function() {request_suicide()},
  "player.suicide")

console.register_command(function(weaponSlotName) {drop_weap_from_slot(weaponSlotName)},
  "inventory.drop_weap_from_slot")

console.register_command(function(equipmentSlotName) {drop_gear_from_slot(equipmentSlotName)},
  "inventory.drop_gear_from_slot")

console.register_command(function(weaponSlotName, weapModSlotName) {remove_item_from_weap_to_inventory(weaponSlotName, weapModSlotName)},
  "inventory.remove_item_from_weap")

console.register_command(function(weaponSlotName) {unload_weapon_ammo_to_inventory(weaponSlotName)},
  "player.request_unload_weapon")

console.register_command(function(weaponSlotName) {request_weapon_reload(weaponSlotName)},
  "player.request_weapon_reload")

console.register_command(function(weaponSlotName) {choose_weapon(weaponSlotName)},
  "player.choose_weapon")

console.register_command(function(){
  local hero = get_controlled_hero()
  local weapInfo = ::ecs.get_comp_val(hero, "human_weap.weapInfo")

  foreach (idx, weap in weapInfo)
    for (local i = 0; i < weap.numReserveAmmo; ++i)
      ::ecs.g_entity_mgr.createEntity("{0}".subst(weap.reserveAmmoTemplate), { ["item.lastOwner"] = ::ecs.EntityId(hero) },
        function(ammoEid) {
          ::ecs.get_comp_val(hero, "itemContainer").append(::ecs.EntityId(ammoEid))
        })
}, "player.rearm")

console.register_command(function(){
  local hero = get_controlled_hero()
  local camNames = ::ecs.get_comp_val(hero, "camNames")

  if (camNames.getAll().indexof("shooter_tps_cam") == null) {
    camNames.append("shooter_tps_cam")
    ::ecs.set_comp_val(hero, "camNames", camNames)
  }
}, "player.enable_tps_camera")

console.register_command(function(){
  local hero = get_controlled_hero()
  local vehicle = ::ecs.get_comp_val(hero, "human_anim.vehicleSelected")
  if (vehicle == INVALID_ENTITY_ID)
    return
  local camNames = ::ecs.get_comp_val(vehicle, "camNames")

  if (camNames.getAll().indexof("plane_cam") == null) {
    camNames.append("plane_cam")
    ::ecs.set_comp_val(vehicle, "camNames", camNames)
  }
}, "plane.enable_tps_cam")
 