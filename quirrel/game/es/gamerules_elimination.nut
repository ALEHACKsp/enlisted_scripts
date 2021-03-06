local { TEAM_UNASSIGNED } = require("team")
local {EventTeamMemberLeave, EventTeamLost} = require("teamevents")
local {EventAnyEntityDied} = require("deathevents")
local {find_connected_player_that_possess} = require("globals/common_queries.nut")

local lastMemberQuery = ::ecs.SqQuery("lastMemberQuery", {comps_rw = ["team.roundScore"], comps_ro = ["team.id"]})
local setTimerQuery = ::ecs.SqQuery("setTimerQuery", {comps_rq = ["team_respawner"]})
local function onLastMember(comp) {
  comp["elimination.numDeaths"] = comp["elimination.numDeaths"] + 1
  local myTeam = comp["team.id"]
  lastMemberQuery.perform(
    function(eid, comp) {
      comp["team.roundScore"] += 1
    }, "ne(team.id,{0})".subst(myTeam))
  if (comp["elimination.numDeaths"] >= comp["elimination.maxRounds"])
    ::ecs.g_entity_mgr.broadcastEvent(EventTeamLost(comp["team.id"]))
  else {
    // force respawn by query
    setTimerQuery.perform(function(team_eid, team_comp) {
      ::ecs.set_timer({eid=team_eid, id="respawn_timer", interval=0.5, repeat=false})
    })
  }
}

local checkLastMemberQuery = ::ecs.SqQuery("checkLastMemberQuery", {comps_ro = ["team", "possessed"], comps_rq=["player"]})
local function checkLastMember(comp, pl_eid) {
  // iterate through players only
  if (!comp["team.haveNoSpawn"])
    return

  local aliveMembers = 0
  checkLastMemberQuery.perform(function(p_eid, p_comp) {
    if (p_eid != pl_eid && p_comp["team"] != comp["team.id"] && ::ecs.get_comp_val(comp["possessed"], "isAlive", false))
      aliveMembers++
    }
  )
  if (aliveMembers==0)
    onLastMember(comp)
}

local function onEntityDied(evt, eid, comp) {
  local reid = evt[0]
  if (comp["team.id"] == ::ecs.get_comp_val(reid, "team", TEAM_UNASSIGNED)) {
    local plEid = find_connected_player_that_possess(reid) ?? INVALID_ENTITY_ID
    checkLastMember(comp, plEid)
  }
}

local function onMemberLeft(evt, eid, comp) {
  if (comp["team.id"] == evt[1])
    checkLastMember(comp, evt[0])
}

local comps = {
  comps_rw = [
    ["elimination.numDeaths", ::ecs.TYPE_INT],
  ]
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.haveNoSpawn", ::ecs.TYPE_BOOL],
    ["elimination.maxRounds", ::ecs.TYPE_INT],
  ]
}

::ecs.register_es("gamerules_elimination_es", {
  [EventAnyEntityDied] = onEntityDied,
  [EventTeamMemberLeave] = onMemberLeft,
}, comps, {tags = "server"})

 