local userInfo = require("enlist/state/userInfo.nut")
local modalWindows = require("daRg/components/modalWindows.nut")
local steam = require("steam")
local auth = require("auth")
local {get_setting_by_blk_path} = require("settings")

local isSteamRunning = persist("isSteamRunning", @() Watched(steam.is_running()))
local isLoggedIn = keepref(Computed(@() userInfo.value != null))
local linkSteamAccount = persist("linkSteamAccount", @() Watched(false))
local disableNetwork = get_setting_by_blk_path("debug")?.disableNetwork ?? false

local function logOut() {
  log("logout")
  modalWindows.hideAll()
  userInfo.update(null)
}

auth.set_auth_token_renew_fail_cb(function() {
  log("logout due to auth token renew failure")
  logOut()
})

return {
  logOut = logOut
  isLoggedIn = isLoggedIn
  isSteamRunning = isSteamRunning
  linkSteamAccount = linkSteamAccount
  disableNetwork = disableNetwork
}
 