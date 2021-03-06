local videomode = require("videomode")

local { monitorValue } = require("monitor_state.nut")

// load it from blk on init
local availableResolutions = videomode.get_video_modes(monitorValue.value)
local resolutionList = Watched(availableResolutions.list)
local resolutionValue = Watched(availableResolutions.current)

monitorValue.subscribe(function(val){
  availableResolutions = videomode.get_video_modes(monitorValue.value)
  resolutionList(availableResolutions.list)
  resolutionValue("auto")
})

return {
  resolutionList = resolutionList
  resolutionValue = resolutionValue
} 