local premiumState = require("enlisted/enlist/meta/clientApi.nut").profile.premium
local serverTime = require("enlist/userstat/serverTime.nut")

local premiumEndTime = ::Computed(@() (premiumState.value?.premium_data.endsAtMs ?? 0) / 1000)

local hasPremium = ::Computed(@() premiumEndTime.value > serverTime.value)

local premiumActiveTime = ::Computed(@()
  ::max(premiumEndTime.value - serverTime.value, 0))

console.register_command(@() console_print(premiumActiveTime.value), "meta.showPremiumLeft")

return {
  hasPremium = hasPremium
  premiumEndTime = premiumEndTime
  premiumActiveTime = premiumActiveTime
}
 