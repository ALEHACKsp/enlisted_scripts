local grenadeIconNames = {
  fougasse = "grenade_fougasse_icon.svg"
  antitank = "grenade_antitank_icon.svg"
  flame = "grenade_flame_icon.svg"
  flash = "grenade_flash_icon.svg"
  smoke = "grenade_smoke_icon.svg"
  signal_flare = "grenade_signal_flare.svg"
  witch_bag = "hex_bag_icon.svg"
}

local grenadeIcon = @(gType, size)
  ::Picture("ui/skin#{0}:{1}:{2}:K".subst(grenadeIconNames?[gType] ?? grenadeIconNames.fougasse, size[0], size[1]))

return grenadeIcon 