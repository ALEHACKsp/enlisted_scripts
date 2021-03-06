local serverTime = require("enlist/userstat/serverTime.nut")
local { settings } = require("enlist/options/onlineSettings.nut")
local { TIME_DAY_IN_SECONDS } = require("utils/time.nut")


const DONT_SHOW_TODAY_ID = "dontShowToday"

local curDay = ::Computed(@() serverTime.value / TIME_DAY_IN_SECONDS)
local dontShowTodayDays = ::Computed(@() settings.value?[DONT_SHOW_TODAY_ID] ?? {})

local dontShowToday = ::Computed(function() {
  local day = curDay.value
  return dontShowTodayDays.value.map(@(d) d >= day)
})

local function setDontShowTodayByKey(key, value) {
  if ((dontShowToday.value?[key] ?? false) == value)
    return
  local day = curDay.value
  local list = dontShowTodayDays.value.filter(@(d) d >= day)
  if (value)
    list.__update({ [key] = day })
  else
    delete list[key]
  settings[DONT_SHOW_TODAY_ID] <- list
}

console.register_command(@() settings[DONT_SHOW_TODAY_ID] <- {}, "dontShowAgain.reset")

return {
  dontShowToday = dontShowToday
  setDontShowTodayByKey = setDontShowTodayByKey
} 