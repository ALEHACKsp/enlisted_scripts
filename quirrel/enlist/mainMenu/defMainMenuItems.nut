local platform = require("globals/platform.nut")
local { showControlsMenu } = require("ui/hud/menus/controls_setup.nut")
local { showSettingsMenu } = require("ui/hud/menus/settings_menu.nut")
local {exitGameMsgBox, logoutMsgBox} = require("enlist/mainMsgBoxes.nut")
local openUrl = require("enlist/openUrl.nut")
local {gaijinSupportUrl} = require("enlist/components/supportUrls.nut")
local qrWindow = require("qrWindow.nut")

local SEPARATOR = null
const GSS_URL = "https://gss.gaijin.net/"

local btnOptions = {
  name = ::loc("gamemenu/btnOptions")
  id = "Options"
  cb = function() {
    showSettingsMenu(true)
  }
}
local btnControls = {
  id = "Controls"
  name = ::loc("gamemenu/btnBindKeys")
  cb = function() {
    showControlsMenu(true)
  }
}
local btnExit = {
  id = "Exit"
  name = ::loc("Exit Game")
  cb = exitGameMsgBox
}
local btnLogout = {
  id = "Exit"
  name = ::loc("Exit Game")
  cb = logoutMsgBox
}
local allowUrl = platform.is_pc || platform.is_sony || platform.is_nswitch
local btnGSS = {
  id = "Gss"
  name = ::loc("gss")
  cb = @() allowUrl ? openUrl(GSS_URL) : qrWindow(GSS_URL, ::loc("gss"))
}
local btnSupport = {
  id = "Support"
  name = ::loc("support")
  cb = @() allowUrl ? openUrl(gaijinSupportUrl) : qrWindow(gaijinSupportUrl, ::loc("support"))
}

return {
  btnControls
  btnOptions
  btnLogout  btnExit
  btnGSS
  btnSupport
  SEPARATOR
} 