local {exit_game_on_disconnect} = require("app")
local {EventOnDisconnectedFromServer} = require("gameevents")
local {ConnErr} = ::ecs

local msgbox = require("ui/components/msgbox.nut")

local connErrMessages = {
  [ConnErr.CONNECTION_CLOSED] = ::loc("ConnErr/CONNECTION_CLOSED"),
  [ConnErr.CONNECTION_LOST] = ::loc("ConnErr/CONNECTION_LOST"),
  [ConnErr.CONNECT_FAILED] = ::loc("ConnErr/CONNECT_FAILED"),
  [ConnErr.CONNECT_FAILED_PROTO_MISMATCH] = ::loc("ConnErr/CONNECT_FAILED_PROTO_MISMATCH"),
  [ConnErr.SERVER_FULL] = ::loc("ConnErr/SERVER_FULL"),
  [ConnErr.WAS_KICKED_OUT] = ::loc("ConnErr/WAS_KICKED_OUT"),
  [ConnErr.KICK_AFK] = ::loc("ConnErr/KICK_AFK"),
}


local function onDisconnectedFromServer(evt, eid, comp) {
  local err_code = evt[0]
  local msgText = ::loc("network/disconnect_message").subst({
    err = connErrMessages?[err_code] ?? ::loc("ConnErr/UNKNOWN")
  })
  msgbox.show({
    text = msgText
    onClose = @() exit_game_on_disconnect()
  })
}

::ecs.register_es("ui_disconnecet_from_server_es", {
  [EventOnDisconnectedFromServer] = onDisconnectedFromServer,
})
 