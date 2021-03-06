local {take_screenshot_nogui, take_screenshot} = require("screencap")
local voiceHotkeys = require("globals/voiceControl.nut")

local eventHandlers = {
    ["Global.Screenshot"] = @(...) take_screenshot(),
    ["Global.ScreenshotNoGUI"] = @(...) take_screenshot_nogui()
  }
foreach (k, v in voiceHotkeys.eventHandlers)
  eventHandlers[k] <- v

return { eventHandlers = eventHandlers }
 