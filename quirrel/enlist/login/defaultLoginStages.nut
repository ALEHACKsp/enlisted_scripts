local platform = require("globals/platform.nut")
local { disableNetwork } = require("login_state.nut")

return disableNetwork ? require("chains/login_pc.nut")
  : platform.is_xdk ? require("chains/login_xbox.nut")
  : platform.is_gdk ? require("chains/login_xbox_gdk.nut")
  : platform.is_sony ? require("chains/login_ps4.nut")
  : platform.is_nswitch ? require("chains/login_nswitch.nut")
  : require("chains/login_pc.nut")
 