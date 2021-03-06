local deactivateGroup = require("game/utils/deactivate_group.nut")
local {EventZoneDecaptured} = require("zoneevents")

local function onZoneDecaptured(evt, eid, comp) {
  local zoneEid = evt[0]
  if (zoneEid != eid)
    return

  deactivateGroup(comp["capzone.activateAfterCap"])
  deactivateGroup(comp["capzone.activateAfterTeam1Cap"])
  deactivateGroup(comp["capzone.activateAfterTeam2Cap"])
}

::ecs.register_es("decapzone_on_deactivate_es", {
    [EventZoneDecaptured] = onZoneDecaptured,
  },
  {
    comps_ro = [
      ["groupName", ::ecs.TYPE_STRING],
      ["capzone.activateAfterCap", ::ecs.TYPE_STRING],
      ["capzone.activateAfterTeam1Cap", ::ecs.TYPE_STRING],
      ["capzone.activateAfterTeam2Cap", ::ecs.TYPE_STRING],

    ]
  },
  {tags="server"}
)

 