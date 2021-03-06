local checkbox = require("ui/components/checkbox.nut")
local {matchRandomTeam, isInQueue, leaveQueue, joinQueue} = require("enlist/quickMatchQueue.nut")

local randTeamCheckbox = checkbox(
  matchRandomTeam,
  {
    text = ::loc("queue/join_any_team")
    font = Fonts.medium_text
    color = Color(255,255,255)
  },
  {
    function setValue(val){
      if (isInQueue.value) {
        leaveQueue(function() {
          matchRandomTeam(val)
          joinQueue()
        })
      }
      else
        matchRandomTeam(val)
    }
    textOnTheLeft = true
  }
)

return {
  randTeamCheckbox
} 