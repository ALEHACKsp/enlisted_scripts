local { TEAM_UNASSIGNED } = require("team")
local {EventTeamLost} = require("teamevents")
local {EventAnyEntityDied} = require("deathevents")

local teamAliveMembersQuery = ::ecs.SqQuery("teamAliveMembersQuery", {comps_ro=[["team", ::ecs.TYPE_INT],["isAlive", ::ecs.TYPE_BOOL]],comps_rq=["countAsAlive"]}, "isAlive")

local function onEntityDied(evt, eid, comp) {
  local victimEid = evt[0]
  local team = ::ecs.get_comp_val(victimEid, "team", TEAM_UNASSIGNED)
  if (team != comp["team.id"])
    return
  local deathPenalty = comp["team.deathPenalty"]
  deathPenalty += comp["team.members"].len() * comp["team.deathPenaltyByMember"]
  deathPenalty = ::max(deathPenalty, comp["team.minDeathPenalty"])
  if (deathPenalty > 0)
    if (deathPenalty >= comp["team.score"]) {
      comp["team.score"] = 0
      if (comp["team.zeroScoreFailTimer"] < 0) {
        ::ecs.g_entity_mgr.broadcastEvent(EventTeamLost(comp["team.id"]))
        return
      }
    }
    else
      comp["team.score"] -= deathPenalty

  if (comp["team.zeroScoreFailTimer"] > 0) {
    local team_alive_player_count = 0
    teamAliveMembersQuery.perform(function(eid, comp) {
      team_alive_player_count++
    }, "and(eq(isAlive,true),eq(team,{0}))".subst(comp["team.id"]))
    if (comp["team.score"] <= 0 && team_alive_player_count == 0) {
      ::ecs.g_entity_mgr.broadcastEvent(EventTeamLost(comp["team.id"]))
    }
  }
}

::ecs.register_es("team_on_death_es",
  {
    [EventAnyEntityDied] = onEntityDied,
  },
  {
    comps_rw = [
      ["team.score", ::ecs.TYPE_FLOAT],
    ]

    comps_ro = [
      ["team.id", ::ecs.TYPE_INT],
      ["team.deathPenalty", ::ecs.TYPE_FLOAT],
      ["team.members", ::ecs.TYPE_ARRAY],
      ["team.deathPenaltyByMember", ::ecs.TYPE_FLOAT, 0],
      ["team.minDeathPenalty", ::ecs.TYPE_FLOAT, 0],
      ["team.zeroScoreFailTimer", ::ecs.TYPE_FLOAT],
    ]
  },
  {tags = "server"}
)

 