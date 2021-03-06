local userInfo = require("enlist/state/userInfo.nut")
local steam = require("steam")
local auth = require("auth")
local openUrl = require("enlist/openUrl.nut")
local { get_circuit_conf } = require("app")

local isLinked = keepref(Computed(@() !steam.is_running() || (userInfo.value?.tags ?? []).indexof("steamlogin") == null))
local isOpenLinkUrlInProgress = Watched(false)

local function openLinkUrl() {
  local url = get_circuit_conf().steamBindUrl
  if (!url || url == "")
    return log("Steam Email Registration: empty url in network.blk")

  isOpenLinkUrlInProgress(true)
  auth.get_steam_link_token(function(res) {
    local token = res?.token ?? ""
    if (token == "")
      log("Steam Email Registration: empty token")
    else
      openUrl(url.subst({ token = token, langAbbreviation = ::loc("langAbbreviation") }))
    isOpenLinkUrlInProgress(false)
  })
}

return {
  openSteamLinkUrl = openLinkUrl
  isSteamLinked = isLinked
  isOpenSteamLinkUrlInProgress = isOpenLinkUrlInProgress
} 