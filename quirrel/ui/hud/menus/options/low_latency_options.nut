local { get_setting_by_blk_path } = require("settings")
local { get_low_latency_state } = require("videomode")

const LOW_LATENCY_BLK_PATH = "video/latency"

const LOW_LATENCY_UNAVAILABLE = -1
const LOW_LATENCY_OFF = 0
const LOW_LATENCY_ON = 1
const LOW_LATENCY_BOOST = 2

local lowLatencyToString = {
  [LOW_LATENCY_OFF] = "option/off",
  [LOW_LATENCY_ON] = "option/on",
  [LOW_LATENCY_BOOST] = "option/boost"
}

local lowLatencyAvailable = ::Computed(function() {
  if (get_low_latency_state() != LOW_LATENCY_UNAVAILABLE)
    return [LOW_LATENCY_OFF, LOW_LATENCY_ON, LOW_LATENCY_BOOST]
  return [LOW_LATENCY_OFF]
})

local lowLatencySupported = ::Computed(function() {
  return get_low_latency_state() != LOW_LATENCY_UNAVAILABLE
})

local lowLatencyValueChosen = ::Watched(get_setting_by_blk_path(LOW_LATENCY_BLK_PATH))

local lowLatencySetValue = @(v) lowLatencyValueChosen(v)

local lowLatencyValue = ::Computed(@() lowLatencyAvailable.value.indexof(lowLatencyValueChosen.value) != null
  ? lowLatencyValueChosen.value : LOW_LATENCY_OFF)

return {
  LOW_LATENCY_BLK_PATH = LOW_LATENCY_BLK_PATH
  LOW_LATENCY_OFF = LOW_LATENCY_OFF
  lowLatencyAvailable = lowLatencyAvailable
  lowLatencyValue = lowLatencyValue
  lowLatencySetValue = lowLatencySetValue
  lowLatencyToString = lowLatencyToString
  lowLatencySupported = lowLatencySupported
} 