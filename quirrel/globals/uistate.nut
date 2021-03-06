local sharedWatched = require("globals/sharedWatched.nut")
local showCreateRoom = persist("showCreateRoom", @() Watched(false))
local controllerDisconnected = sharedWatched("controllerDisconnected", @() false)
local actionInProgress = sharedWatched("actionInProgress", @() false)

return {
  showCreateRoom = showCreateRoom
  controllerDisconnected = controllerDisconnected
  actionInProgress = actionInProgress
}
 