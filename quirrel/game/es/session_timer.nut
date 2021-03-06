  
                                                                                                      
                                                             
  
local { TEAM_UNASSIGNED } = require("team")
local {EventTeamWon} = require("teamevents")

local findBestTeamQuery = ::ecs.SqQuery("findBestTeamQuery", {comps_ro = [["team.roundScore", ::ecs.TYPE_INT], ["team.id", ::ecs.TYPE_INT]]})
local function onSessionTimeFinished(){
  local maxRoundScore = 0
  local bestTeamId = TEAM_UNASSIGNED
  findBestTeamQuery.perform(function(eid, comp) {
    local rscore = comp["team.roundScore"]
    if (rscore > maxRoundScore) {
      maxRoundScore = rscore
      bestTeamId = comp["team.id"]
    }
  })
  ::ecs.g_entity_mgr.broadcastEvent(EventTeamWon(bestTeamId))
}

local function onUpdate(dt, eid, comp) {
  local timeLeft = comp["session_timer.time_left"]
  if (timeLeft < 0.0)
    return

  timeLeft -= dt
  comp["session_timer.time_left"] = timeLeft
  if (timeLeft < 0.0)
    onSessionTimeFinished()
}

::ecs.register_es("session_timer_es",
  {onUpdate = onUpdate},
  {comps_rw = [["session_timer.time_left",::ecs.TYPE_FLOAT]]},
  { updateInterval = 1.0, tags = "server", after="*", before="*" }
)

 