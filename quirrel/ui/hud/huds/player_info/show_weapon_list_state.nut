local {isEqual} = require("std/underscore.nut")
local {localPlayersBattlesPlayed} = require("ui/hud/state/player_state_es.nut")
local {weaponsList} = require("ui/hud/state/hero_state.nut")

const playerBattlesForLongerTimeShow = 5
const showLongerTime = 6
const showShorterTime = 3

local showWeaponsBlockAlways = Watched(true)
local showWeapons = Watched(false)
local showWeaponsBlockMinTime = Watched(showLongerTime)

local showWeaponsTimeout = ::Computed(@() localPlayersBattlesPlayed.value > playerBattlesForLongerTimeShow ? showShorterTime : showLongerTime)
local offShowWeapons = @() showWeapons(false)

local function activateShowWeapons(){
  showWeapons(true)
  if (!showWeaponsBlockAlways.value){
    ::gui_scene.clearTimer(offShowWeapons)
    ::gui_scene.setTimeout(::max(showWeaponsTimeout.value, showWeaponsBlockMinTime.value), offShowWeapons)
  }
}


local showWeaponList = Watched(false)

local weaponlistTimer = @() showWeaponList.update(false)

local function weaponlistActivate() {
  local weaponTimeout = showWeaponsTimeout.value
  showWeaponList.update(true)
  activateShowWeapons()
  ::gui_scene.clearTimer(weaponlistTimer)
  ::gui_scene.setTimeout(weaponTimeout, weaponlistTimer)
}

local weaponsListShort = ::Computed(function(){
  local res = []
  foreach (weapon in weaponsList.value){
    if (weapon?.isCurrent)
      res.append({isCurrent=true, name = weapon?.name, isHolstering = weapon?.isHolstering})
    else
      res.append({isCurrent=false, curAmmo = weapon?.curAmmo, name = weapon?.name, totalAmmo = weapon?.totalAmmo, isHolstering = weapon?.isHolstering})
  }
  return res
})
keepref(weaponsListShort)

local function handleWListChanges(watched) {
  local weapons_prev = watched.value
  local function onWeaponListChange(new_val) {
    if (!isEqual(weapons_prev, new_val)) {
      weaponlistActivate()
    }
    weapons_prev = new_val
  }
  watched.subscribe(onWeaponListChange)
}
handleWListChanges(weaponsListShort)

return{
  showWeaponList = showWeaponList
  weaponlistActivate = weaponlistActivate
  showWeapons = showWeapons
  activateShowWeapons = activateShowWeapons
  showWeaponsBlockAlways = showWeaponsBlockAlways
  showWeaponsBlockMinTime = showWeaponsBlockMinTime
} 