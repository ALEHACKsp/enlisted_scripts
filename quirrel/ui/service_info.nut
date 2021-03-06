local {DBGLEVEL} = require("dagor.system")
local sessionId = require("ui/hud/huds/session_id.ui.nut")
local {mkFpsBar} = require("fpsBar.nut")
local platform = require("globals/platform.nut")

local fpsBar = mkFpsBar({vplace = DBGLEVEL==0 ? ALIGN_BOTTOM : null})

local function serviceInfo() {
  local children = (platform.is_pc || DBGLEVEL>0) ? [fpsBar] : []
  return {
    children = children.append(sessionId)
    flow = FLOW_HORIZONTAL valign = ALIGN_BOTTOM size = flex() padding = [::hdpx(2), ::hdpx(10)]
  }
}
return {serviceInfo, fpsBar} 