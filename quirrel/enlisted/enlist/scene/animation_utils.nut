local remapWeaponToAnimState = require("menu_poses_for_weapons.nut")
local dagorRandom = require("dagor.random")
local string = require("string")

local function getWeapTemplate(template){
  ::assert(::type(template)=="string")
  return string.split(template, "+")?[0] ?? template
}

local SLOTS_ORDER = ["primary", "secondary", "tertiary"]
local firstAvailableWeapon = @(tmpls)
  tmpls?[SLOTS_ORDER.findvalue(@(key) (tmpls?[key] ?? "") != "")] ?? ""

local function getIdleAnimState(weapTemplates, animationBlacklist = null, seed = null) {
  if (seed==null)
    seed = dagorRandom.grnd()
  if (seed<0)
    seed = -seed
  local idle = remapWeaponToAnimState?["defaultPoses"]
  local weaponTemplate = getWeapTemplate(firstAvailableWeapon(weapTemplates))
  if (weaponTemplate == "")
    idle = ["enlisted_idle_0{0}".subst(1 + (seed % 4))]
  else {
    idle = remapWeaponToAnimState?[weaponTemplate] ?? idle
  }
  if (animationBlacklist != null) {
    for (local i = idle.len() - 1; i >= 0; --i) {
      if (idle[i] in animationBlacklist)
        idle.remove(i)
    }
  }
  return idle?[seed % idle.len()] ?? "enlisted_idle_11_weapon"
}

return {
  getIdleAnimState = getIdleAnimState
}
 