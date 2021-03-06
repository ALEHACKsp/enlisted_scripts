local {addScene, removeScene} = require("enlist/navState.nut")
local roomState = require("enlist/state/roomState.nut")
local {showCreateRoom} = require("globals/uistate.nut")

local progressText = require("enlist/components/progressText.nut")
local roomScreen = require("enlist/roomScreen.nut")
local roomsList = require("enlist/roomsList.nut")
local closeBtnBase = require("enlist/components/closeBtn.nut")


local customGamesContent = @() {
  watch = [roomState.room, roomState.roomIsLobby]
  size = flex()
  children = !roomState.room.value ? roomsList
    : roomState.roomIsLobby.value ? roomScreen
    : progressText(::loc("lobbyStatus/gameIsRunning"))
}


local isCustomGamesOpened = persist("isCustomGamesOpened", @() Watched(false))
local close = @() isCustomGamesOpened(false)

local closeBtn = closeBtnBase({ onClick = @() showCreateRoom.value ? showCreateRoom(false) : close() })

local customGamesScene = @() {
  watch = roomState.room
  size = flex()
  margin = [sh(5), sw(5)]
  children = [
    customGamesContent
    roomState.room.value ? null : closeBtn
  ]
}


isCustomGamesOpened.subscribe(
  function(val) {
    if (val)
      addScene(customGamesScene)
    else
      removeScene(customGamesScene)
  })


return {
  customGamesScene,
  customGamesOpen = @() isCustomGamesOpened(true),
  customGamesClose = close,
  isCustomGamesOpened
} 