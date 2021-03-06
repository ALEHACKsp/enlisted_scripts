local {EventTeamLost, EventTeamWon, EventTeamRoundResult} = require("teamevents")

local function onTeamLost(evt, eid, comp) {
  local team = comp["team.id"]
  ::ecs.g_entity_mgr.broadcastEvent(EventTeamRoundResult(team, team != evt[0]))
}

local function onTeamWon(evt, eid, comp) {
  local team = comp["team.id"]
  ::ecs.g_entity_mgr.broadcastEvent(EventTeamRoundResult(team, team == evt[0]))
}


::ecs.register_es("team_on_lost_es",
  {
    [EventTeamLost] = onTeamLost,
    [EventTeamWon] = onTeamWon,
  },
  { comps_ro = [ ["team.id", ::ecs.TYPE_INT],]},
  {tags = "server"}
)


 