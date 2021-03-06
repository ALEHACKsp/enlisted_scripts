require("connectingToServerMsg.nut")
require("globals/notifications/disconnectedControllerMsg.nut")
require("globals/notifications/actionInProgressMsg.nut")

local {gameClientActive} = require("gameLauncher.nut")
local {forceRefreshUnlocks, refreshUserstats} = require("userstat/userstat.nut")

gameClientActive.subscribe(function(isActive) {
  if (!isActive)
    ::gui_scene.setTimeout(1.0, function() {
      refreshUserstats()
      forceRefreshUnlocks()
    })
})
 