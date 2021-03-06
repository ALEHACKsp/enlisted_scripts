local { TEAM0_COLOR_FG, TEAM1_COLOR_FG} = require("ui/hud/style.nut")
local { WARNING_PRIORITIES, addWarnings, warningUpdate } = require("ui/hud/state/warnings.nut")
local { myScore, enemyScore } = require("team_scores.nut")
local { debriefingShow } = require("enlisted/ui/hud/state/debriefingStateInBattle.nut")

const WE_LEAD = "score/weLead"
const ENEMY_LEAD = "score/enemyLead"
const WE_HALF = "score/weHalf"
const ENEMY_HALF = "score/enemyHalf"
const WE_LOW = "score/weLow"
const ENEMY_LOW = "score/enemyLow"

local positiveMessage = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10, color = TEAM0_COLOR_FG }
local negativeMessage = { priority = WARNING_PRIORITIES.LOW, timeToShow = 10, color = TEAM1_COLOR_FG }

addWarnings({
  [WE_LEAD] = positiveMessage,
  [ENEMY_LEAD] = negativeMessage,
  [WE_HALF] = negativeMessage,
  [ENEMY_HALF] = positiveMessage,
  [WE_LOW] = negativeMessage,
  [ENEMY_LOW] = positiveMessage,
})

local state = keepref(::Computed(function() {
  local my = myScore.value ?? 0
  local enemy = enemyScore.value ?? 0
  return {
    inited             = my > 0 && enemy > 0
    list = {
      [WE_LEAD]        = 0.9 * my >= enemy,
      [ENEMY_LEAD]     = my <= 0.9 * enemy,
      [WE_HALF]        = my <= 0.5,
      [ENEMY_HALF]     = enemy <= 0.5,
      [WE_LOW]         = my <= 0.1,
      [ENEMY_LOW]      = enemy <= 0.1,
    }
  }
}))
local prevState = state.value

state.subscribe(function(newState) {
  if (newState.inited && prevState.inited && !debriefingShow.value)
    foreach(id, value in newState.list)
      if (value != prevState.list[id])
        warningUpdate(id, value)
  prevState = newState
})

debriefingShow.subscribe(@(v) state.value.list.each(@(_, id) warningUpdate(id, false)))
 