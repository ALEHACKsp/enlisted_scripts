local { TEAM_UNASSIGNED } = require("team")
local debug = require("std/log.nut")().with_prefix("[TEAM]")
local random = require("dagor.random")

local assignTeamQuery = ::ecs.SqQuery("assignTeamQuery", {comps_ro =
  [
    ["team.members", ::ecs.TYPE_ARRAY],
    ["team.memberCount", ::ecs.TYPE_FLOAT],
    ["team.id", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["team.newTeamTemplate", ::ecs.TYPE_STRING, ""],
    ["team.capacity", ::ecs.TYPE_INT, -1],
    ["team.locked", ::ecs.TYPE_BOOL, false],
  ]
})

local newTeamQuery = ::ecs.SqQuery("newTeamQuery", {comps_rw = [["team.locked", ::ecs.TYPE_BOOL, false]] comps_ro = [["team.capacity", ::ecs.TYPE_INT]]})

local function assign_team() { // returns [teamId, teamEid]
  local maxTeamTid = 0
  local availableTeams = []
  local templateToCreate = null
  local minTeamMembers = 1 << 30
  assignTeamQuery(
    function(eid, comp) {
      local tid = comp["team.id"]
      maxTeamTid = ::max(maxTeamTid, tid)
      templateToCreate = comp["team.newTeamTemplate"]
      if ((comp["team.capacity"] >= 0 && comp["team.members"].len() >= comp["team.capacity"]) || comp["team.locked"])
        return
      minTeamMembers = ::min(minTeamMembers, comp["team.memberCount"])
      availableTeams.append(eid)
    })

  if (availableTeams.len() == 0 && templateToCreate != null) {
    // create new teams
    local teamId = maxTeamTid + 1
    local comps = {
      ["team.id"] = teamId,
      ["team.should_lock"] = true
    }
    local teamEid = ::ecs.g_entity_mgr.createEntitySync(templateToCreate, comps)
    newTeamQuery(teamEid,
      function (eid, comp) {
        if (comp["team.capacity"] == 1)
          comp["team.locked"] = true
      })
    debug($"Created new team with id: {teamId}, eid: {teamEid}")
    return [teamId, teamEid]
  }

  if (minTeamMembers == 1 << 30) { // empty teams?
    debug("No team found")
    return [TEAM_UNASSIGNED, INVALID_ENTITY_ID]
  }

  local filteredTeams = []
  foreach (eid in availableTeams) {
    if (::ecs.get_comp_val(eid, "team.memberCount", 0.0) == minTeamMembers)
      filteredTeams.append(eid)
  }

  local teamEid = filteredTeams[random.grnd() % filteredTeams.len()]
  local teamId = ::ecs.get_comp_val(teamEid, "team.id", TEAM_UNASSIGNED)
  debug($"Found already existing team with id: {teamId}, eid: {teamEid}")
  return [teamId, teamEid]
}

return assign_team
 