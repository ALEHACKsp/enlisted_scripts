local frp  = require("std/frp.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {heroSquadNumAliveMembers} = require("enlisted/ui/hud/state/hero_squad.nut")
local {warningUpdate, WARNING_PRIORITIES, addWarnings} = require("ui/hud/state/warnings.nut")
local { debounce } = require("utils/timers.nut")
local {mkCountdownTimerPerSec} = require("ui/helpers/timers.nut")

local scoresByTeams = persist("scoresByTeamsWatched", @()::Watched({}))

local myTeamCanFailByTime = persist("myTeamCanFailByTime", @() ::Watched(false))
local canIncreaseScore = persist("canIncreaseScore", @() ::Watched(false))

addWarnings({
  waitTeamScores = { priority = WARNING_PRIORITIES.MEDIUM, timeToShow = 10, locId = "respawn/no_spawn_scores" }
  zeroScoreFailTimer     = { priority = WARNING_PRIORITIES.MEDIUM, timeToShow = 10 },
  scoreIsLow             = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10 },
  scoreIsHalf            = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10 },
})

local failEndTime = Watched(0)

local myScore = Watched(0)
local myRoundScore = Watched(0)
local myScoreBleed = Watched(0)
local myScoreBleedFast = Watched(0)

local enemyScore = Watched(0)
local enemyRoundScore = Watched(0)
local enemyScoreBleed = Watched(0)
local enemyScoreBleedFast = Watched(0)

local paramsBySideMap = {
  my = {
    score      = myScore
    roundScore = myRoundScore
    bleed      = myScoreBleed
    bleedFast  = myScoreBleedFast
  }
  enemy = {
    score      = enemyScore
    roundScore = enemyRoundScore
    bleed      = enemyScoreBleed
    bleedFast  = enemyScoreBleedFast
  }
}

local isShownZeroScoreWarn = false
local function updateScoreWarning() {
  local isMySquadDead = heroSquadNumAliveMembers.value == 0
  local needZeroScoreWarn = !isMySquadDead && failEndTime.value > 0 && myTeamCanFailByTime.value
  if (needZeroScoreWarn != isShownZeroScoreWarn) {
    warningUpdate("zeroScoreFailTimer", needZeroScoreWarn)
    isShownZeroScoreWarn = needZeroScoreWarn
  }
  warningUpdate("waitTeamScores", isMySquadDead && failEndTime.value > 0 && canIncreaseScore.value)
}

frp.subscribe([failEndTime, heroSquadNumAliveMembers, myTeamCanFailByTime, canIncreaseScore],
  debounce(@(_) updateScoreWarning(), 0.1))


local scoreIsLowTriggered = false
local scoreIsHalfTriggered = false
local function setScoreParams(teamScores, side) {
  local normScore
  normScore = teamScores["team.scoreCap"] > 0 ? teamScores["team.score"] / teamScores["team.scoreCap"].tofloat() : null
  paramsBySideMap[side].score(normScore)
  paramsBySideMap[side].roundScore(teamScores["team.roundScore"])

  if (teamScores["team.scoreCap"] > 0 && teamScores["team.squadSpawnCost"] > 0 && side == "my") {
    local needWarnLow = normScore <= 0.2
    local needWarnHalf = normScore <= 0.5
    if (scoreIsLowTriggered != needWarnLow) {
      warningUpdate("scoreIsLow", needWarnLow && !scoreIsLowTriggered)
      scoreIsLowTriggered = needWarnLow
    }
    if (scoreIsHalfTriggered != needWarnHalf) {
      warningUpdate("scoreIsHalf", needWarnHalf  && !needWarnLow && !scoreIsHalfTriggered)
      scoreIsHalfTriggered = needWarnHalf
    }
  }
}

local function setBleedParams(teamScores, side) {
  paramsBySideMap[side].bleed(teamScores["score_bleed.domBleedOn"])
  paramsBySideMap[side].bleedFast(teamScores["score_bleed.domBleedOn"] && teamScores["score_bleed.totalDomBleedOn"])
}

frp.subscribe([localPlayerTeam, scoresByTeams], function(_){
  local endTime = -1
  foreach (teamId, teamScores in scoresByTeams.value) {
    if (!teamScores["team.haveScores"])
      continue
    local side = (teamId == localPlayerTeam.value) ? "my" : "enemy"
    if (side == "my") {
      myTeamCanFailByTime(teamScores["team.failEndTime"] > 0)
      canIncreaseScore(teamScores["team.scoreCap"] > 0)
    }

    setScoreParams(teamScores, side)
    setBleedParams(teamScores, side)

    local teamTime = teamScores["team.failEndTime"]
    if (teamTime >= 0 && (endTime < 0 || endTime > teamTime))
      endTime = teamTime
  }
  failEndTime(endTime)
})

local teamComps = {
  comps_track = [
    ["team.score", ::ecs.TYPE_FLOAT],
    ["team.squadSpawnCost", ::ecs.TYPE_INT, 0],
    ["team.failEndTime", ::ecs.TYPE_FLOAT, 0.0],
    ["team.roundScore", ::ecs.TYPE_INT, 0],
    ["team.scoreCap", ::ecs.TYPE_FLOAT],
    ["team.haveScores", ::ecs.TYPE_BOOL, true],
    ["score_bleed.domBleedOn", ::ecs.TYPE_BOOL],
    ["score_bleed.totalDomBleedOn", ::ecs.TYPE_BOOL],
  ]
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT]
  ]
}

local function trackComponents(evt, eid, comp) {
  local val = {}
  foreach (ctype, compslist in teamComps) {
    foreach (compdesc in compslist)
      val[compdesc[0]] <- comp[compdesc[0]]
  }
  local teamId = comp["team.id"]
  scoresByTeams(function(scores) {
    scores[teamId] <- val
  })
}


local function onDestroy(evt, eid, comp) {
  local teamId = comp["team.id"]
  scoresByTeams(function(scores) {
    delete scores[teamId]
  })

}


::ecs.register_es("team_game_mode_scores_ui_es", {
  [["onChange","onInit"]] = trackComponents
  onDestroy = onDestroy
}, teamComps)

return {
  myTeamFailEndTime = failEndTime
  myTeamFailTimer = mkCountdownTimerPerSec(failEndTime)
  myScore = myScore
  myRoundScore = myRoundScore
  myScoreBleed = myScoreBleed
  myScoreBleedFast =myScoreBleedFast
  enemyScore = enemyScore
  enemyRoundScore = enemyRoundScore
  enemyScoreBleed = enemyScoreBleed
  enemyScoreBleedFast = enemyScoreBleedFast
} 