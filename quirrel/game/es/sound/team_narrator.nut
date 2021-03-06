local { TEAM_UNASSIGNED } = require("team")
local {sound_play} = require("sound")
local {get_controlled_hero} = require("globals/common_queries.nut")
local {EventTeamWon, EventTeamLost, EventTeamLowScore, EventTeamLoseHalfScore} = require("teamevents")

local function onTeamWon(evt, eid, comp) {
  if (evt[0] == comp["team.id"])
    sound_play(comp["team.narrator_win"])
}

local function onTeamLost(evt, eid, comp) {
  if (evt[0] == comp["team.id"])
    sound_play(comp["team.narrator_lose"])
}

local function onTeamLowScore(evt, eid, comp) {
  if (evt[0] == comp["team.id"]) {
    local heroTeam = ::ecs.get_comp_val(get_controlled_hero(), "team", TEAM_UNASSIGNED)
    sound_play(comp["team.id"] == heroTeam ? comp["team.narrator_weLoosingScores"] : comp["team.narrator_theyLoosingScores"])
  }
}

local function onTeamLoseHalfScore(evt, eid, comp) {
  if (evt[0] == comp["team.id"]) {
    local heroTeam = ::ecs.get_comp_val(get_controlled_hero(), "team", TEAM_UNASSIGNED)
    sound_play(comp["team.id"] == heroTeam ? comp["team.narrator_weLoseHalfScores"] : comp["team.narrator_theyLoseHalfScores"])
  }
}

::ecs.register_es("narrator_sound_es", {
    [EventTeamWon] = onTeamWon,
    [EventTeamLost] = onTeamLost,
    [EventTeamLowScore] = onTeamLowScore,
    [EventTeamLoseHalfScore] = onTeamLoseHalfScore,
  },
  {
    comps_ro = [
      ["team.id", ::ecs.TYPE_INT],
      ["team.narrator_win", ::ecs.TYPE_STRING],
      ["team.narrator_lose", ::ecs.TYPE_STRING],
      ["team.narrator_weLoosingScores", ::ecs.TYPE_STRING],
      ["team.narrator_theyLoosingScores", ::ecs.TYPE_STRING],
      ["team.narrator_weLoseHalfScores", ::ecs.TYPE_STRING],
      ["team.narrator_theyLoseHalfScores", ::ecs.TYPE_STRING],
    ]
  },{tags="sound"}
)
 