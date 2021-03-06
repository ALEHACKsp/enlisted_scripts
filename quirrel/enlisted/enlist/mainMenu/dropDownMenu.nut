local { navHeight } = require("mainmenu.style.nut")
local { mkDropMenuBtn } = require("enlist/components/mkDropDownMenu.nut")
local { btnOptions, btnControls, btnExit, btnLogout, SEPARATOR, btnGSS } = require("enlist/mainMenu/defMainMenuItems.nut")
local gameLauncher = require("enlist/gameLauncher.nut")
local { curBattleTutorial } = require("enlisted/enlist/tutorial/battleTutorial.nut")
local { openDailyScene } = require("enlisted/enlist/deliveries/deliveriesState.nut")
local { openChangelog } = require("enlisted/enlist/openChangelog.nut")
local wipFeatures = require("enlisted/globals/wipFeatures.nut")
local { lobbyEnabled } = require("enlist/roomsListState.nut")
local { isInQueue } = require("enlist/quickMatchQueue.nut")
local { customGamesOpen } = require("enlist/customGamesWnd.nut")
local debugProfileWnd = require("enlisted/enlist/mainMenu/debugProfileWnd.nut")
local debugConfigsWnd = require("enlisted/enlist/mainMenu/debugConfigsWnd.nut")
local { get_client_user_permissions } = require("globals/client_user_permissions.nut")
local userInfo = require("enlist/state/userInfo.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local { DBGLEVEL } = require("dagor.system")
local { is_xbox, is_sony } = require("globals/platform.nut")


local deliveriesBtn = {
  id = "Deliveries"
  name = ::loc("delivery/header_daily")
  cb = openDailyScene
}

local btnCustomGames = {
  id  = "CustomGames"
  name = ::loc("Custom games")
  cb = customGamesOpen
}

local btnChangelog = {
  id = "Changelog"
  name = ::loc("gamemenu/btnChangelog")
  cb = openChangelog
}

local btnDebugProfile = {
  id = "DebugProfile"
  name = ::loc("Debug Profile")
  cb = debugProfileWnd
}

local btnDebugConfigs = {
  id = "DebugConfigs"
  name = ::loc("Debug Configs")
  cb = debugConfigsWnd
}

local btnDevToggleMonetization = {
  id = "ToggleMonetization"
  name = @() $"DEV: {monetization.value ? "disable" : "enable"} monetization"
  cb = @() monetization(!monetization.value)
}

local needCustomGames = ::Computed(@() lobbyEnabled.value && !isInQueue.value)
local canDebugProfile = ::Computed(@() DBGLEVEL > 0
  || get_client_user_permissions(userInfo.value?.userId ?? -1).debug_server_data)
local canEnableMonetization = ::Computed(@() DBGLEVEL > 0
  || canDebugProfile.value
  || get_client_user_permissions(userInfo.value?.userId ?? -1).debug_monetization
)

local buttons = ::Computed(function() {
  local res = []
  if (needCustomGames.value)
    res.append(btnCustomGames)
  if (wipFeatures.hasDeliveries)
    res.append(deliveriesBtn)
  if (curBattleTutorial.value != null)
    res.append({
      id = "Tutorial"
      name = ::loc("TUTORIAL")
      cb = @() gameLauncher.startGame({ game = "enlisted", scene = curBattleTutorial.value }, @(...) null)
    })
  res.append(btnChangelog)
  if (res.len() > 0)
    res.append(SEPARATOR)
  res.append(btnOptions, btnControls, btnGSS)
  if (!is_sony) {
    if (is_xbox)
      res.append(btnLogout)
    else
      res.append(btnExit)
  }
  if (canDebugProfile.value)
    res.append(SEPARATOR, btnDebugProfile, btnDebugConfigs)
  if (canEnableMonetization.value)
    res.append(SEPARATOR, btnDevToggleMonetization)
  return res
})

return mkDropMenuBtn({buttons, size = [navHeight*0.75, navHeight]})
 