local {playerEvents} = require("eventlog.nut")
local {EventOnGunBlocksShoot} = require("gameevents")

::ecs.register_es("gun_blocked_es", {
  [EventOnGunBlocksShoot] = function onGunBlocked(evt, eid, comp){
    local reason = evt[0]
    playerEvents.pushEvent({event="gun_blocked", text = ::loc(reason), myTeamScores=false})
  },
}, { comps_rq = ["hero"] }, {tags="gameClient"})

 