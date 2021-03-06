local {playerEvents} = require("ui/hud/state/eventlog.nut")
local {makeItem} = require("ui/hud/components/mkPlayerEvents.nut")
local showPlayerHuds = require("ui/hud/state/showPlayerHuds.nut")

local function playerEventsRoot() {
  return {
    flow   = FLOW_VERTICAL
    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM
    size   = [pw(80), SIZE_TO_CONTENT]
    clipChildren = true
    watch = [playerEvents.events, showPlayerHuds]
    children = showPlayerHuds.value ? playerEvents.events.value.map(makeItem) : null
  }
}


return playerEventsRoot
 