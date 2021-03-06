local iconSize = ::hdpx(22)

local itemTypesSvg = {
  boltaction_noscope = "rifle.svg"
  rifle_grenade_launcher = "rifle.svg"
  antitank_rifle = "rifle.svg"

  mgun = "machine_gun.svg"
  assault_rifle = "machine_gun.svg"

  submgun = "submachine_gun.svg"
  semiauto = "submachine_gun.svg"

  boltaction = "sniper_rifle.svg"
  semiauto_sniper = "sniper_rifle.svg"

  shotgun = "shotgun.svg"
  launcher = "launcher.svg"
  mortar = "mortarman.svg"
  flamethrower = "flametrooper.svg"

  vehicle = "tank_icon.svg"
  tank = "tank_icon.svg"
  aircraft = "aircraft_icon.svg"
  assault_aircraft = "aircraft_icon.svg"
  fighter_aircraft = "aircraft_icon.svg"

  itemparts = "research/weapon_parts_boost_icon.svg"
}

local function soldierItemTypeIcon(
  itemType, itemSubType = null, size = iconSize, color = null
) {
  local img = itemTypesSvg?[itemSubType] ?? itemTypesSvg?[itemType]
  if (img == null)
    return null
  return {
    rendObj = ROBJ_IMAGE
    size = array(2, size)
    image = ::Picture($"ui/skin#{img}:{size}:{size}:K")
    tint = color
  }
}

return ::kwarg(soldierItemTypeIcon)
 