local { TEAM_UNASSIGNED } = require("team")
local debug = require("std/log.nut")().with_prefix("[PLAYER]")
local {get_team_eid} = require("globals/common_queries.nut")
local assign_team = require("game/utils/team.nut")
local {INVALID_CONNECTION_ID, add_entity_in_net_scope, get_sync_time} = require("net")

local {EventOnPlayerConnected, CmdSpawnSquad} = require("respawnevents")
local {EventTeamMemberJoined} = require("teamevents")

local groupMatesQuery = ::ecs.SqQuery("groupMatesQuery", {
  comps_ro = [["team", ::ecs.TYPE_INT], ["groupId", ::ecs.TYPE_INT64]]
  comps_rq = ["player"]
})

local function onPlayerConnected(evt, eid, comp) {
  local wishTeam = evt[0]
  local reconnected = evt[1]
  local canSpawnEntity = evt[2]

  local groupId = comp.groupId
  local possessed = comp.possessed
  local team = comp.team

  if (wishTeam == TEAM_UNASSIGNED && team != TEAM_UNASSIGNED)
    wishTeam = team

  debug($"Player {eid} with team {team} and groupId {groupId} has been connected and wish to join {wishTeam} team.")

  groupMatesQuery(function(gmEid, gmComp) {
    if (gmEid != eid && gmComp.groupId == groupId && gmComp.team != TEAM_UNASSIGNED) {
      wishTeam = gmComp.team
      return true
    }
  })

  if (wishTeam == TEAM_UNASSIGNED) {
    local [teamId, teamEid] = assign_team()
    debug($"Player {eid} wish to join any team due to wishTeam is {wishTeam}. Assign team {teamId}.")

    wishTeam = teamId
    if (comp.connid != INVALID_CONNECTION_ID)
      add_entity_in_net_scope(teamEid, comp.connid)
  }

  if (reconnected && ::ecs.g_entity_mgr.doesEntityExist(possessed)) {
    if (!::ecs.get_comp_val(possessed, "isAlive", false)) {
      ::ecs.g_entity_mgr.destroyEntity(possessed)

      comp.possessed = INVALID_ENTITY_ID
      comp.team = wishTeam
    }
    else if (!::ecs.get_comp_val(get_team_eid(team),"team.allowRebalance", false))
      comp.team = wishTeam
  }
  else
    comp.team = wishTeam

  if (comp.team == team)
    debug($"Player {eid} team {comp.team} it the same.")
  else
    debug($"Player {eid} team has been changed from {team} to {comp.team}")

  comp.connectedAtTime = get_sync_time()

  // on reconnect to aborted connection (i.e. disconnect of old connection wasn't handled) possessed entity might still exist
  if (canSpawnEntity && !::ecs.g_entity_mgr.doesEntityExist(possessed)) {
    debug($"Spawn spuad for team {comp.team} and player {eid}")
    ::ecs.g_entity_mgr.sendEvent(eid, CmdSpawnSquad(comp.team, INVALID_ENTITY_ID, 0, 0, -1));
  }

  if (comp.team != TEAM_UNASSIGNED)
    ::ecs.g_entity_mgr.broadcastEvent(EventTeamMemberJoined(eid, comp.team))
}

::ecs.register_es("player_on_connect_script_es", {
  [EventOnPlayerConnected] = onPlayerConnected,
},
{
  comps_rw=[
    ["team", ::ecs.TYPE_INT],
    ["possessed", ::ecs.TYPE_EID],
    ["connectedAtTime", ::ecs.TYPE_FLOAT],
  ]
  comps_ro=[
    ["groupId", ::ecs.TYPE_INT64],
    ["connid", ::ecs.TYPE_INT, INVALID_CONNECTION_ID]
  ]
  comps_rq=["player"]
})
 