local {makeEcsHandlers} = require("ui/mk_ecshandlers.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")

local teams = persist("teams", @() ::Watched({}))

local localPlayerTeamInfo = ::Computed(function(){
  foreach (eid, team in teams.value) {
    if (team?["team.id"] != null && team?["team.id"] == localPlayerTeam.value)
      return team
  }
  return null
})
local localPlayerTeamMemberCount = ::Computed(@() localPlayerTeamInfo.value?["team.memberCount"])
local localPlayerTeamIcon = ::Computed(@() localPlayerTeamInfo.value?["team.icon"])
local localPlayerTeamSquadsCanSpawn = ::Computed(@() localPlayerTeamInfo.value?["team.squadsCanSpawn"] ?? true)
local localPlayerTeamArmy = ::Computed(@() localPlayerTeamInfo.value?["team.army"] ?? "")

local teamsState = {
  teams = teams
  localPlayerTeamIcon = localPlayerTeamIcon
  localPlayerTeamMemberCount = localPlayerTeamMemberCount
  localPlayerTeamInfo = localPlayerTeamInfo
  localPlayerTeamSquadsCanSpawn = localPlayerTeamSquadsCanSpawn
  localPlayerTeamArmy = localPlayerTeamArmy
}

local teams_comps = {
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.name", ::ecs.TYPE_STRING, ""],
    ["team.icon", ::ecs.TYPE_STRING, ""],
    ["team.army", ::ecs.TYPE_STRING, ""],
  ]
  comps_track = [
    ["team.memberCount", ::ecs.TYPE_FLOAT, 0.0],
    ["team.haveNoSpawn", ::ecs.TYPE_BOOL, false],
    ["team.briefing", ::ecs.TYPE_STRING, ""],
    ["team.narrator_briefing", ::ecs.TYPE_STRING, ""],
    ["team.narrator_pointCaptured", ::ecs.TYPE_STRING, ""],
    ["team.narrator_pointCapturedEnemy", ::ecs.TYPE_STRING, ""],
    ["team.narrator_onePointToCapture", ::ecs.TYPE_STRING, ""],
    ["team.narrator_halfPointsCaptured", ::ecs.TYPE_STRING, ""],
    ["team.narrator_onePointToDefend", ::ecs.TYPE_STRING, ""],
    ["team.narrator_halfPointsCapturedEnemy", ::ecs.TYPE_STRING, ""],
    ["team.narrator_allPointsCapturedAlly", ::ecs.TYPE_STRING, ""],
    ["team.narrator_allPointsCapturedEnemy", ::ecs.TYPE_STRING, ""],
    ["team.narrator_pointCapturingPlayer", ::ecs.TYPE_STRING, ""],
    ["team.narrator_pointCapturingAlly", ::ecs.TYPE_STRING, ""],
    ["team.narrator_pointCapturingEnemy", ::ecs.TYPE_STRING, ""],
    ["team.narrator_leftBattleArea", ::ecs.TYPE_STRING, ""],
    ["team.narrator_taskPoint", ::ecs.TYPE_STRING, ""],
    ["team.narrator_sectorCapturedAlly", ::ecs.TYPE_STRING, ""],
    ["team.narrator_sectorCapturedEnemy", ::ecs.TYPE_STRING, ""],
    ["team.narrator_oneSectorLeft", ::ecs.TYPE_STRING, ""],
    ["team.squadsCanSpawn", ::ecs.TYPE_BOOL, true],
    ["team.eachSquadMaxSpawns", ::ecs.TYPE_INT, 0],
  ]
}

::ecs.register_es("teams_ui_state_es",
  makeEcsHandlers(teams, teams_comps),
  teams_comps
)

return teamsState
 