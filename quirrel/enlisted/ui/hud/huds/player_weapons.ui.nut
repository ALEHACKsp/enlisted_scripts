local playerGrenades = require("ui/hud/huds/player_info/grenades.ui.nut")
local eventHandlersComp = require("ui/hud/huds/player_info/activate_show_weapons_evt_handlers.ui.nut")
local {showWeaponsBlockAlways, showWeaponsBlockMinTime, showWeapons} = require("ui/hud/huds/player_info/show_weapon_list_state.nut")
local { barWidth, DEFAULT_TEXT_COLOR } = require("ui/hud/huds/player_info/style.nut")
local {
  hasWeapon, curWeaponTotalAmmo, curWeaponAmmo, curWeaponIsReloadable, curWeaponHasSwitchableWeaponMods
} = require("ui/hud/huds/player_info/weapons_state.nut")
local {dtext} = require("daRg/components/text.nut")
local vehicleBlock = require("ui/hud/huds/player_info/vehicle_weapons.nut")
local {showVehicleWeapons} = require("ui/hud/huds/player_info/vehicle_turret_state.nut")
local vitalPlayerInfo = require("ui/hud/huds/player_info/vital_player_info.ui.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")
local {mkInputHintBlock} = require("ui/hud/huds/tips/tipComponent.nut")

local humanPlayerWeaponInfo = require("ui/hud/huds/player_info/player_weapons.ui.nut")

local style = {font=Fonts.big_text, color = DEFAULT_TEXT_COLOR, fontFxColor=Color(0,0,0,50) fontFx=FFT_GLOW}
local sep = dtext("/", style)
local ht = ::calc_comp_size(sep)[1]

local weapModToggleHint = mkInputHintBlock("Human.WeapModToggle")
local function weapModToggleTip() {
  return {
    watch = [curWeaponHasSwitchableWeaponMods]
    vplace = ALIGN_CENTER
    children = curWeaponHasSwitchableWeaponMods.value ? [weapModToggleHint] : null
    padding = [0,ht/5,0,0]
  }
}

local playerAmmo = function() {
  local res = { watch = [hasWeapon, curWeaponTotalAmmo, curWeaponAmmo, curWeaponIsReloadable] }
  if (!hasWeapon.value || !curWeaponIsReloadable.value)
    return res
  return res.__update({
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    gap = ht/10
    children = [weapModToggleTip, dtext(curWeaponAmmo.value.tostring(), style), sep, dtext(curWeaponTotalAmmo.value.tostring(), style)]
  })
}

showWeaponsBlockAlways(false)
showWeaponsBlockMinTime(7)
local shortPlayerBlock = {
  flow = FLOW_VERTICAL
  size = SIZE_TO_CONTENT
  halign = ALIGN_RIGHT
  children = [ eventHandlersComp, playerAmmo, playerGrenades]
}

local playerDynamic = @(){
  watch = showWeapons
  children = showWeapons.value ? humanPlayerWeaponInfo : shortPlayerBlock
  size = SIZE_TO_CONTENT
}

local function playerBlock() {
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    size = [barWidth, SIZE_TO_CONTENT]
    gap = sh(0.5)
    watch = [showPlayerHuds, showVehicleWeapons]
    children = showPlayerHuds.value ? [
      !showVehicleWeapons.value ? playerDynamic : null,
      showVehicleWeapons.value ? vehicleBlock : null,
      vitalPlayerInfo
    ] : null
  }
}

return playerBlock 