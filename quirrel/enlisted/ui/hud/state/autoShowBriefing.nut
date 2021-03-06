local {showBriefingOnSquadChange, briefing, showBriefingForTime, showBriefingOnHeroChange} = require("briefingState.nut")
local {squadEid} = require("enlisted/ui/hud/state/hero_squad.nut")
local {controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {localPlayerTeamInfo} = require("enlisted/ui/hud/state/teams.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")

local showedBriefing = {
    //team = {briefing = true}
}
localPlayerTeam.subscribe(@(v) showedBriefing.clear())

local firstSpawnBriefingShown = persist("firstSpawnBriefingShown", @() Watched(false))

controlledHeroEid.subscribe(function(value) {
  local curBriefing = localPlayerTeamInfo.value?["team.briefing"] ?? ""
  local curBriefingCommon = briefing.value?["common"] ?? ""
  local function showBrief(){
    showedBriefing[curBriefing] <- 1
    showedBriefing[curBriefingCommon] <- 1
    showBriefingForTime(briefing.value?.showtime ?? 10.0)
  }
  if (value == INVALID_ENTITY_ID)
    return
  if (!firstSpawnBriefingShown.value){
    firstSpawnBriefingShown(true)
    showBrief()
    return
  }
  if (!showBriefingOnHeroChange.value) {
    return
  }
  showBrief()
})

squadEid.subscribe(function(value){
  if (!showBriefingOnSquadChange.value)
    return
  showBriefingForTime(briefing.value?.showtime ?? 10.0)
})
 