local get_time_msec = require("dagor.time").get_time_msec
local cTime = ::Watched(0)
local function updateCtime(){
  cTime((get_time_msec()/1000).tointeger())
}
::gui_scene.setInterval(1, updateCtime)

return {
  curTimePerSec = cTime
} 