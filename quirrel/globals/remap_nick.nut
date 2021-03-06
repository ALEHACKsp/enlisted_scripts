local {is_xbox, is_sony} = require("platform.nut")
local string = require("string")

local nick_prefix = {
  ["^"] = is_xbox ? "" : "⋉", //xbox live
  ["*"] = is_sony ? "" : "⋊", //psn
}

local nick_suffix = {
  ["@live"] = is_xbox ? "" : "⋉",
  ["@psn"] = is_sony ? "" : "⋊",
  ["@steam"] = "⋈",
  ["@nintendo"] = "@nintendo",
}

local function remapNick(nick){
  if (typeof nick != "string")
    return nick

  foreach(prefix, icon in nick_prefix) {
    if (string.startswith(nick, prefix)) {
      nick = nick.slice(prefix.len())
      return $"{nick}{icon}"
    }
  }
  foreach(suffix, icon in nick_suffix) {
    if (string.endswith(nick, suffix)){
      nick = nick.slice(0, -suffix.len())
      return $"{nick}{icon}"
    }
  }
  return nick
}
return remapNick
 