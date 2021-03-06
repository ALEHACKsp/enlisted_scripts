local { gfrnd } = require("dagor.random")
local { gameClientActive } = require("enlist/gameLauncher.nut")
local matchingNotifications = require("enlist/state/matchingNotifications.nut")
local { update_profile, get_all_configs } = require("clientApi.nut")
local userInfo = require("enlist/state/userInfo.nut")

const MAX_CONFIGS_UPDATE_DELAY = 10 //to prevent all users update configs at once.
  //but after the battle user will update configs if needed with profile even before timer.

local isProfileChanged = persist("isProfileChanged", @() ::Watched(false))
local isConfigsChanged = persist("isConfigsChanged", @() ::Watched(false))

local function checkUpdateProfile() {
  if (gameClientActive.value) {
    isProfileChanged(true)
    return
  }

  if (isConfigsChanged.value)
    get_all_configs()
  update_profile()
  isProfileChanged(false)
  isConfigsChanged(false)
}

gameClientActive.subscribe(function(v) {
  if (isProfileChanged.value)
    checkUpdateProfile()
})

local function updateConfigsTimer() {
  if (isConfigsChanged.value)
    ::gui_scene.setTimeout(gfrnd() * MAX_CONFIGS_UPDATE_DELAY, checkUpdateProfile)
  else
    ::gui_scene.clearTimer(checkUpdateProfile)
}
updateConfigsTimer()
isConfigsChanged.subscribe(@(_) updateConfigsTimer())

userInfo.subscribe(function(u) {
  if (u != null)
    return
  isProfileChanged(false)
  isConfigsChanged(false)
})

matchingNotifications.subscribe("profile",
  @(ev) ev?.func == "updateConfig" ? isConfigsChanged(true) : checkUpdateProfile())
 