enum WeaponSlots {
  EWS_PRIMARY = 0
  EWS_SECONDARY = 1
  EWS_TERTIARY = 2
  EWS_MELEE = 3
  EWS_GRENADE = 4
  EWS_NUM = 5
}

local weaponSlotsKeys = {
  [WeaponSlots.EWS_PRIMARY] = "primary",
  [WeaponSlots.EWS_SECONDARY] = "secondary",
  [WeaponSlots.EWS_TERTIARY] = "tertiary",
  [WeaponSlots.EWS_MELEE] = "melee",
  [WeaponSlots.EWS_GRENADE] = "grenade"
}

return {
  EWS_PRIMARY = WeaponSlots.EWS_PRIMARY
  EWS_SECONDARY = WeaponSlots.EWS_SECONDARY
  EWS_TERTIARY = WeaponSlots.EWS_TERTIARY
  EWS_MELEE = WeaponSlots.EWS_MELEE
  EWS_GRENADE = WeaponSlots.EWS_GRENADE
  EWS_NUM = WeaponSlots.EWS_NUM
  weaponSlotsKeys = weaponSlotsKeys
} 