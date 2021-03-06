local platform = require("globals/platform.nut")

local xbox_show = null
if (platform.is_xdk) {
  xbox_show = require("enlist/xbox/xboxLobby.nut").inviteToSquad
} else if (platform.is_gdk) {
  xbox_show = require("enlist/xbox_gdk/lobby.nut").inviteToSquad
}

local show = (platform.is_xbox)
  ? xbox_show
  : platform.is_nswitch
    ? require("contactsListWndNSwitch.nut")
    : require("contactsListWndCommon.nut")

return {
  show
}
 