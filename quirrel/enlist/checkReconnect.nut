local matchingCli = require("matchingClient.nut")
local { joinRoom, allowReconnect, lastRoomResult } = require("state/roomState.nut")
local { gameClientActive } = require("gameLauncher.nut")
local msgbox = require("enlist/components/msgbox.nut")
local delayed = require("utils/delayedActions.nut")
local isReconnectChecking = persist("isReconnectChecking", @() Watched(false))

local function checkReconnect() {
  if (gameClientActive.value || !allowReconnect.value || isReconnectChecking.value)
    return

  isReconnectChecking(true)
  matchingCli.call("enlmm.check_reconnect",
    function(response) {
      isReconnectChecking(false)
      local roomId = response?.roomId
      if (roomId == null)
        return

      log("found reconnect for room", roomId)
      msgbox.show({
        text = ::loc("do_you_want_to_reconnect"),
        buttons = [
          {
            text = ::loc("Yes")
            action = @() joinRoom({ roomId = roomId }, false, function(...) {})
            isCurrent = true
          },
          {
            text = ::loc("No")
            isCancel = true
          }
        ]

      })
    })
}

lastRoomResult.subscribe(function(result) {
  if (result?.isDisconnect ?? false)
    delayed.add(checkReconnect)
})

return checkReconnect
 