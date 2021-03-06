local defaultWeaponSvg = "rifle.svg"
local weaponSvg = {
  assault_rifle = "assault_rifle.svg"
  pistol = "pistol.svg"
  rifle = "sniper_rifle.svg"
  semiauto = "rifle.svg"
  machine_gun = "machine_gun.svg"
  submachine_gun = "submachine_gun.svg"
  shotgun = "shotgun.svg"
  launcher = "launcher.svg"
  melee = "melee.svg"
  flamethrower = "flamethrower.svg"
  mortar = "mortar.svg"
}
local function mkWeaponTypeIcon(weaponType, iconHeight){
  local weapSvg = weaponSvg?[weaponType]
  return (weapSvg != null) ? ::Picture("ui/skin#{0}:{1}:{1}:K".subst(weapSvg, iconHeight.tointeger())) : null
}

local function hashofWeap(svg, height){
  return (svg == null) ? "___" : "_".concat(svg, height)

}
return {
  weaponSvgByTypeMap = weaponSvg
  defaultWeaponSvg = defaultWeaponSvg
  mkWeaponTypeIco = ::memoize(mkWeaponTypeIcon, hashofWeap)
} 