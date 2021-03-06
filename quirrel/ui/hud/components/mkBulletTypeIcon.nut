local colors = {
  BulletDefault          = Color(50, 72, 74)
  BulletDefaultCurrent   = Color(82, 116, 117)
  MainAmmoColor          = Color(180, 180, 180)
  MainAmmoColorCurrent   = Color(240, 240, 240)
}
local function bulletOriginalColor(isEqupped) {
  return isEqupped ? colors.MainAmmoColorCurrent : colors.MainAmmoColor
}
local function bulletDefaultColor(isEqupped) {
  return isEqupped ? colors.BulletDefaultCurrent : colors.BulletDefault
}

local BULLET_TYPE = { //todo: use bullet icon from template
  DEFAULT = {
    prefix = null,
    icon = "tank/mashine_gun_ammo.svg"
    color = bulletDefaultColor
  }
  DEFAULT_CANNON = {
    prefix = null,
    icon = "tank/cannon_ammo_AP.svg"
    color = bulletOriginalColor
  }
  APHE = {
    prefix = "aphe_"
    icon = "tank/cannon_ammo_AP.svg"
    color = bulletOriginalColor
  }
  APCBC = {
    prefix = "apcbc_"
    icon = "tank/cannon_ammo_AP.svg"
    color = bulletOriginalColor
  }
  APHEBC = {
    prefix = "aphebc_"
    icon = "tank/cannon_ammo_AP.svg"
    color = bulletOriginalColor
  }
  HE = {
    prefix = "he_"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
  HEAT = {
    prefix = "heat_"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
  SHRAPNEL = {
    prefix = "shrapnel"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
  SMOKE = {
    prefix = "smoke"
    icon = "tank/cannon_ammo_HE.svg"
    color = bulletOriginalColor
  }
}

local function getBulletType(weapon) {
  if (weapon?.icon != null)
    return {
      icon = weapon?.icon
      color = bulletOriginalColor
    }
  if (weapon?.bulletType == null) //machine gun have no bullet type. For consistens, show machine gun bullets
    return BULLET_TYPE.DEFAULT

  return BULLET_TYPE.findvalue(@(bt) bt.prefix != null && (weapon?.bulletType.indexof(bt.prefix) ?? -1) == 0)
  ?? BULLET_TYPE.DEFAULT_CANNON //For consistens, show by default any cannon image
}

return function(weapon, size = [hdpx(100).tointeger(), hdpx(100).tointeger()]) {
  local bulletType = getBulletType(weapon)

  return {
    icon = bulletType.icon
    image = ::Picture($"ui/skin#{bulletType.icon}:{size[0]}:{size[1]}:K")
    color = bulletType.color(weapon?.isCurrent ?? true)
  }
} 