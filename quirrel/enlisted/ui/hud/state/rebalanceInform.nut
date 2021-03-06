local {EventPlayerRebalanced} = require("gameevents")
local {playerEvents} = require("ui/hud/state/eventlog.nut")

local function onPlayerRebalanced(evt, eid, comp){
  if (comp["is_local"]) {
    local e = {event="team_change", text=::loc("You have been switched to another team!"), myTeamScores=false}
    playerEvents.pushEvent(e)
  }
}

::ecs.register_es("rebalance_inform_es", {[EventPlayerRebalanced] = onPlayerRebalanced}, {
  comps_ro = [
    ["team", ::ecs.TYPE_INT],
    ["is_local", ::ecs.TYPE_BOOL, false],
  ],
  comps_rq = ["player"]
})

 