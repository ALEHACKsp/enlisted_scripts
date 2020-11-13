local {get_sync_time} = require("net")
local curTime = Watched(0.0)

::gui_scene.setInterval(1.0/60.0, @() curTime(get_sync_time()))
local curTimePerSec = ::Computed(@() (curTime.value+0.5).tointeger())

return {
  curTime = curTime
  curTimePerSec = curTimePerSec
}
 