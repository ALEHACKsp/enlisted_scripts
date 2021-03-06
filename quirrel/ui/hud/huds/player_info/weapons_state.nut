local { curWeapon } = require("ui/hud/state/hero_state.nut")

local totalAmmo = ::Computed(@() curWeapon.value?.totalAmmo ?? 0)
local isReloadable = ::Computed(@() curWeapon.value?.isReloadable ?? ((curWeapon.value?.maxAmmo ?? 0) > 0))
local curAmmo = ::Computed(@() curWeapon.value?.curAmmo ?? 0)
local weaponName = ::Computed(@() curWeapon.value?.name ?? "")
local firingMode = ::Computed(@() curWeapon.value?.firingMode ?? "")
local showWeaponBlock = ::Computed(@() curWeapon.value != null && !curWeapon.value?.isRemoving
      && (curWeapon.value?.changeProgress ?? 100) == 100)
local hasSwitchableWeaponMods = ::Computed(@() curWeapon.value?.hasSwitchableWeaponMods ?? false)

return {
  hasWeapon = ::Computed(@() curWeapon.value != null)
  curWeaponName = weaponName
  curWeaponAmmo = curAmmo
  curWeaponTotalAmmo = totalAmmo
  curWeaponIsReloadable = isReloadable
  curWeaponFiringMode = firingMode
  curWeaponHasSwitchableWeaponMods = hasSwitchableWeaponMods
  showWeaponBlock = showWeaponBlock
}
 