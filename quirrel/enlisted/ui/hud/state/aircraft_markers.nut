local {TEAM_UNASSIGNED} = require("team")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local aircraft_markers = Watched({})

local function deleteEid(eid){
  if (eid in aircraft_markers.value)
    aircraft_markers.update(function(v) {
      delete v[eid]
    })
}

::ecs.register_es(
  "aircraft_markers_es",
  {
    [["onInit", "onChange"]] = function(ect, eid, comp){
      if (!comp.isAlive || comp.team == TEAM_UNASSIGNED || !comp["hud_aircraft_marker.isVisible"])
        deleteEid(eid)
      else
        aircraft_markers.update(@(v) v[eid] <- {
          team         = comp.team,
          isIdentified = comp["hud_aircraft_marker.isIdentified"],
          isFriendly   = localPlayerTeam.value == comp.team
        })
    }
    onDestroy = @(evt, eid, comp ) deleteEid(eid)
  },
  {
    comps_rq = ["hud_aircraft_marker"]
    comps_track = [
      ["isAlive", ::ecs.TYPE_BOOL, false],
      ["team", ::ecs.TYPE_INT, null],
      ["hud_aircraft_marker.isIdentified", ::ecs.TYPE_BOOL, true],
      ["hud_aircraft_marker.isVisible", ::ecs.TYPE_BOOL, true],
    ]
  }
)

return{
  aircraft_markers = aircraft_markers
} 