local { activeCapZonesEids } = require("enlisted/ui/hud/state/capZones.nut")

local zoneCompColor = Color(255, 255, 100, 200)
local zoneCompSize = [hdpx(4), hdpx(4)]
local zoneCompVector = [
  [VECTOR_RECTANGLE, 0, -200, 100, 100],
]
local zoneCompProto = {
  size = zoneCompSize
  color = zoneCompColor
  rendObj = ROBJ_VECTOR_CANVAS

  commands = zoneCompVector

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform = {}
  behaviors = []
}

return @() activeCapZonesEids.value.values()
  .map(@(zone_eid) zoneCompProto.__merge({ data = { eid = zone_eid, clampToBorder = true }})) 