local { TEAM_UNASSIGNED } = require("team")
local { lightgray } = require("daRg/components/std.nut")
local scoringPlayers = require("enlisted/ui/hud/state/scoring_players.nut")
local {localPlayerTeam, localPlayerEid} = require("ui/hud/state/local_player.nut")
local {teams} = require("enlisted/ui/hud/state/teams.nut")
local {myScore, enemyScore} = require("enlisted/ui/hud/state/team_scores.nut")
local { visibleZoneGroups, whichTeamAttack } = require("enlisted/ui/hud/state/capZones.nut")

local mkScoresStatistics = require("enlisted/ui/hud/components/mkScoresStatistics.nut")
local JB = require("ui/control/gui_buttons.nut")
local { removeInteractiveElement, hudIsInteractive, switchInteractiveElement
} = require("ui/hud/state/interactive_state.nut")
local {verPadding} = require("globals/safeArea.nut")
local { capzoneWidget } = require("enlisted/ui/hud/components/capzone.nut")


local showScores = persist("showScores", @() Watched(false))
local function getScoresTeams() {
  local teamsV = {}
  foreach (team in teams.value)
    if ((team?["team.id"] ?? TEAM_UNASSIGNED) != TEAM_UNASSIGNED)
      teamsV[team["team.id"].tostring()] <- { icon = team?["team.icon"] }

  return teamsV
}

local titleText = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_DTEXT
  font = Fonts.medium_text
}

local zoneParams = {
  customBack = @(v) null
  canHighlight = false
  animAppear = []
  animActive = []
  margin = 0
}

local function mkTeamScore(isMyTeam) {
  local scoreWatch = isMyTeam ? myScore : enemyScore
  local isDefend = ::Computed(@() whichTeamAttack.value != -1
    && (whichTeamAttack.value == localPlayerTeam.value) != isMyTeam)
  local halign = isMyTeam ? ALIGN_LEFT :ALIGN_RIGHT
  return function() {
    if (!isDefend.value)
      return titleText.__merge({
        watch = [scoreWatch, isDefend]
        halign = halign
        text = scoreWatch.value == null ? null
          : ::loc("teamHeader/score", { score = (1000.0 * scoreWatch.value + 0.5).tointeger() })
      })

    return {
      watch = [visibleZoneGroups, isDefend]
      size = [flex(), SIZE_TO_CONTENT]
      halign = halign
      flow = FLOW_HORIZONTAL
      gap = ::hdpx(10)
      children = visibleZoneGroups.value.reduce(@(res, v) res.extend(v), [])
        .map(@(zEid) capzoneWidget(zEid, zoneParams))
    }
  }
}

local title = {
  size = [flex(), ::hdpx(40)]
  valign = ALIGN_CENTER
  children = [
    mkTeamScore(true)
    titleText.__merge({
      halign = ALIGN_CENTER
      color = lightgray
      text = ::loc("multiplayerscores/title")
    })
    mkTeamScore(false)
  ]
}

const interactiveKey = "scores"
local eventHandlers = {
  ["HUD.Interactive"] = function onHudInteractive(event) {
    switchInteractiveElement(interactiveKey)
  },
  ["HUD.Interactive:end"] = function onHudInteractiveEnd(event) {
    if (showScores.value && ((event?.dur ?? 0) > 500 || event?.appActive == false)){
      removeInteractiveElement(interactiveKey)
    }
  }
}
showScores.subscribe(function(v) {
  if (!v)
    removeInteractiveElement(interactiveKey)
})

local scoresMenuUi = {
  size = flex()
  halign = ALIGN_CENTER
  padding = [verPadding.value + sh(5), 0, verPadding.value, 0]
  flow = FLOW_VERTICAL
  children = [
    { size = [0, flex(1)] }
    @() mkScoresStatistics(scoringPlayers.value, {
      localPlayerEid = localPlayerEid.value
      myTeam = localPlayerTeam.value
      teams = getScoresTeams()
      title = title
      showBg = true
      scrollIsPossible = true
      hotkeys = [["^{0} | Esc".subst(JB.B), {
            action = @() showScores.update(false)
            description = ::loc("Close"),
            inputPassive = true
        }]]

    }).__update({
      eventHandlers = eventHandlers
      watch = [ scoringPlayers, localPlayerTeam, localPlayerEid, hudIsInteractive, verPadding]
      hooks = HOOK_ATTACH
      actionSet = "Scores"
      sound = {
        attach = "ui/stat_on"
        detach = "ui/stat_off"
      }
    })
    { size = [0, flex(3)] }
  ]
}

return {
  showScores = showScores
  scoresMenuUi = scoresMenuUi
} 