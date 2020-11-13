local wallposterMenuItems = persist("items", @()::Watched([]))
local radius = ::hdpx(365)
local showWallposterMenu = persist("showWallposterMenu", @() ::Watched(false))

return {
  wallposterMenuItems = wallposterMenuItems
  radius = ::Watched(radius)
  elemSize = ::Watched([(radius*0.35).tointeger(),(radius*0.35).tointeger()])
  showWallposterMenu = showWallposterMenu
}
 