local {bindSquadROVar, bindSquadRWVar} = require("enlist/squad/squadState.nut")
local {gameClientActive} = require("enlist/gameLauncher.nut")
local {selectedQueue} = require("enlist/quickMatchQueue.nut")

bindSquadROVar("inBattle", gameClientActive)
bindSquadRWVar("ready", persist("myExtData.ready", @() Watched(false)))
bindSquadROVar("selectedQueue", selectedQueue)

 