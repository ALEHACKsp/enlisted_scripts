local iconWidget = require("ui/hud/components/icon3d.nut")
//we have to build one image size for the sane dynAtlas
local inventoryItemAnimations = {
  def = null
}
local inventoryImageSz =[ sh(5)-hdpx(8), sh(5)-hdpx(8)]
local inventoryImageParams = ::memoize(@(animation) {width=inventoryImageSz[0], height=inventoryImageSz[1], transform = {}, animations = inventoryItemAnimations[animation]})
local weaponIconParams  ={width=hdpx(256), height=hdpx(80)}
local weaponModIconParams = {width=sh(14)-sh(1.2), height=sh(4.5)-sh(1.2) hplace=ALIGN_CENTER outline=[64,64,64,12] margin=hdpx(1)}

local itemIconImage = @(icon, animation) {
  size = inventoryImageSz
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = ::Picture($"!ui/{icon}")
  transform = {}
  animations = inventoryItemAnimations[animation]
}

return {
  function inventoryItemImage(item) {
    return (item?.iconImage ?? "") == ""
      ? iconWidget(item, inventoryImageParams(item?.animation ?? "def"))
      : itemIconImage(item.iconImage, item?.animation ?? "def")
  }
  function iconWeapon(weapon) {
    return iconWidget(weapon, weaponIconParams)
  }
  function weaponModImage(modSlot) {
    return iconWidget(modSlot, weaponModIconParams)
  }
  inventoryItemAnimations = inventoryItemAnimations
}

 