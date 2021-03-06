local loginState = require("login/login_state.nut")
local userInfo = require("state/userInfo.nut")
local matchingCli = require("matchingClient.nut")
local msgbox = require("components/msgbox.nut")
local gameLauncher = require("gameLauncher.nut")
local app = require("enlist.app")
require("unlogingHandler.nut")
require("state/customRooms.nut")
require("squad/commonExtData.nut")
require("registerConsoleCmds.nut")

local checkReconnect = require("checkReconnect.nut")

::gui_scene.setShutdownHandler(function() {
  msgbox.widgets.update([])
})

local delayedLogout = persist("delayedLogout", @() { need = false })

// if matching client forced client to logout do not interrupt current game session
// perform logout after session is finished
gameLauncher.gameClientActive.subscribe(
  function (active) {
    if (!active && delayedLogout.need) {
      app.on_logout()
      delayedLogout.need = false
    }
  }
)

loginState.isLoggedIn.subscribe(function (state) {
  if (state) {
    app.on_login_complete(userInfo.value.userId)
  }
  else {
    if (!gameLauncher.gameClientActive.value) {
      app.on_logout()
    }
    else {
      delayedLogout.need = true
    }
  }
})

matchingCli.connected.subscribe(
  function (is_connected) {
    if (is_connected)
      checkReconnect()
  }
)

if (!("__loc" in getroottable()))
  ::__loc<-::loc

 