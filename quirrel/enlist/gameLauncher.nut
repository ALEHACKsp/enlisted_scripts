local app = require("enlist.app")
local statsd = require("statsd")
local msgbox = require("enlist/components/msgbox.nut")

local gameClientActive = persist("gameClientActive" @() Watched(false))
local lastGame = persist("lastGame", @() Watched(null))

local function onGameFinished(isDisconnect, cb) {
  gameClientActive.update(false)
  cb(isDisconnect)
}

local function startGame(params, cb) {
  console_print("Launching game client...")
  debugTableData(params.filter(@(v,k) k!="authKey"))

  if (gameClientActive.value) {
    msgbox.show({text=::loc("msgboxtext/gameIsRunning")})
    return
  }

  gameClientActive.update(true)
  app.launch_network_game(params, @(isDisconnect) onGameFinished(isDisconnect, cb))
  statsd.send_counter("game_launch", 1)
  lastGame(params)
}

return {
  gameClientActive = gameClientActive
  startGame = startGame
  lastGame = lastGame
}
 