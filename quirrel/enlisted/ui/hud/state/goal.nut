local { debounce } = require("utils/timers.nut")
local { briefing } = require("briefingState.nut")
local { localPlayerTeamInfo } = require("enlisted/ui/hud/state/teams.nut")
local { hints } = require("ui/hud/state/eventlog.nut")
local { needSpawnMenu, respawnsInBot } = require("enlisted/ui/hud/state/respawnState.nut")

local isWaitToShow = ::Watched(false)

local goalText = ::Computed(function() {
  local locId = localPlayerTeamInfo.value?["team.briefing"] ?? ""
  if (locId == "")
    locId = briefing.value?.briefing_common ?? ""
  return locId == "" ? "" : ::loc($"{locId}/short", ::loc(locId))
})

local showGoal = @() hints.pushEvent({ uid = "goal", text = goalText.value })
local function showGoalWhenReady() {
  if (needSpawnMenu.value)
    isWaitToShow(true)
  else
    showGoal()
}

goalText.subscribe(@(_) showGoalWhenReady())
needSpawnMenu.subscribe(function(show) {
  if (show || !isWaitToShow.value)
    return
  isWaitToShow(false)
  showGoal()
})


local markShowAfterSpawn = debounce(function() {
  if (needSpawnMenu.value && !respawnsInBot.value)
    isWaitToShow(true)
}, 0.5)
needSpawnMenu.subscribe(@(_) markShowAfterSpawn())
respawnsInBot.subscribe(@(_) markShowAfterSpawn())

console.register_command(showGoal, "ui.add_goal_msg") 