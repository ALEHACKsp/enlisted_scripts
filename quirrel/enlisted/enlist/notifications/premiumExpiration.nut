local JB = require("ui/control/gui_buttons.nut")
local serverTime = require("enlist/userstat/serverTime.nut")
local { TIME_DAY_IN_SECONDS } = require("utils/time.nut")
local { hasPremium, premiumActiveTime } = require("enlisted/enlist/currency/premium.nut")
local userInfo = require("enlist/state/userInfo.nut")
local { settings } = require("enlist/options/onlineSettings.nut")
local { monetization } = require("enlisted/enlist/featureFlags.nut")
local msgbox = require("enlist/components/msgbox.nut")
local premiumWnd = require("enlisted/enlist/currency/premiumWnd.nut")
local { sendBigQueryUIEvent } = require("enlist/bigQueryEvents.nut")

const SETTINGS_ID = "premium/notification"
local BASE_WAIT_TIME = TIME_DAY_IN_SECONDS
local MAX_WAIT_TIME = 30 * TIME_DAY_IN_SECONDS

local waitReset = @() settings(function(set) {
  if (SETTINGS_ID in set)
    delete set[SETTINGS_ID]
})

local function waitNext() {
  local waitTime = settings.value?[SETTINGS_ID].waitTime ?? BASE_WAIT_TIME
  settings(@(set) set[SETTINGS_ID] <- {
    nextWarnTime = serverTime.value + waitTime
    waitTime = min(2 * waitTime, MAX_WAIT_TIME)
  })
}

local function checkExpiration() {
  if (!monetization.value)
    return

  local nextWarnTime = settings.value?[SETTINGS_ID].nextWarnTime
  if (premiumActiveTime.value > 0) {
    if (nextWarnTime)
      waitReset()
    return
  }

  if (nextWarnTime == null) {
    waitNext()
    return
  }

  if (serverTime.value < nextWarnTime)
    return

  msgbox.show({
    text = ::loc("premium/premiumSuggest")
    buttons = [
      {
        text = ::loc("btn/buy")
        action = function() {
          premiumWnd()
          sendBigQueryUIEvent("open_premium_window", "premium_expired")
        }
        customStyle = { hotkeys = [["^J:Y"]] }
      }
      {
        text = ::loc("Ok")
        isCurrent = true
        isCancel = true
        customStyle = { hotkeys = [["^{0} | Esc".subst(JB.B)]] }
      }
    ]
    onClose = @() waitNext()
  })
}

userInfo.subscribe(@(val) val ? checkExpiration() : null)
hasPremium.subscribe(@(_) checkExpiration())

local dumpExpInfo = @()
  console_print($"Premium expiration as {SETTINGS_ID}:", settings.value?[SETTINGS_ID])
console.register_command(@() dumpExpInfo(), "meta.dumpPremiumExpiration")
console.register_command(@() checkExpiration(), "meta.checkPremiumExpiration")
console.register_command(@() waitReset(), "meta.resetPremiumExpiration")
console.register_command(function() {
  waitNext()
  dumpExpInfo()
}, "meta.nextPremiumExpiration")
 