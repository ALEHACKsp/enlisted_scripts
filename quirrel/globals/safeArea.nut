local {get_setting_by_blk_path} = require("settings")
local math = require("math")
local sharedWatched = require("globals/sharedWatched.nut")
local mkOnlineSaveData = require("enlist/options/mkOnlineSaveData.nut")
local platform = require("globals/platform.nut")

local blkPath = "video/safeArea"
local safeAreaList = (platform.is_xbox) ? [0.9, 0.95, 1.0]
  : platform.is_sony ? [require("sony").getDisplaySafeArea()]
  : [1.0]
local canChangeInOptions = @() safeAreaList.len() > 1

local function validate(val) {
  if (safeAreaList.indexof(val) != null)
    return val
  local res = null
  foreach(v in safeAreaList)
    if (res == null || math.fabs(res - val) > math.fabs(v - val))
      res = v
  return res
}
local safeAreaDefault = @() canChangeInOptions() ? validate(get_setting_by_blk_path(blkPath) ?? safeAreaList.top())
  : safeAreaList.top()

local amountStorage = mkOnlineSaveData("safeAreaAmount", safeAreaDefault,
  @(value) canChangeInOptions() ? validate(value) : safeAreaDefault())
local storedAmount = amountStorage.watch

local debugAmount = sharedWatched("debugSafeArea", @() null)
local show = sharedWatched("showSafeArea", @() false)

local function setAmount(val) {
  amountStorage.setValue(val)
  debugAmount(null)
}

local amount = ::Computed(@() debugAmount.value ?? storedAmount.value)
local horPadding = ::Computed(@() sw(100*(1-amount.value)/2))
local verPadding = ::Computed(@() sh(100*(1-amount.value)/2))

console.register_command(@() show(!show.value), "ui.safeAreaShow")

console.register_command(
  function(val = 0.9) {
    if (val > 1.0 || val < 0.9) {
      vlog(@"SafeArea is supported between 0.9 (lowest visible area) and 1.0 (full visible area).
This range is according console requirements. (Reset to used in options)")
      debugAmount(null)
      return
    }
    debugAmount(val)
  }, "ui.safeAreaSet"
)

return {
  verPadding
  horPadding

  safeAreaCanChangeInOptions = canChangeInOptions
  safeAreaBlkPath = blkPath
  safeAreaVerPadding = verPadding
  safeAreaHorPadding = horPadding
  safeAreaSetAmount = setAmount
  safeAreaAmount = amount
  safeAreaShow = show
  safeAreaList = safeAreaList
}
 