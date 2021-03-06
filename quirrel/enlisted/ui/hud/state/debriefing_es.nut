local {pow} = require("math")
local {get_sync_time} = require("net")
local {debriefingShow, debriefingData} = require("debriefingStateInBattle.nut")
local {localPlayerNamePrefixIcon, localPlayerKills, localPlayerDeaths, localPlayerAwards} = require("ui/hud/state/player_state_es.nut")
local {localPlayerTeamInfo} = require("enlisted/ui/hud/state/teams.nut")
local {localPlayerName, localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {EventTeamRoundResult} = require("teamevents")
local remap_nick = require("globals/remap_nick.nut")
local { get_session_id } = require("app")
local { missionName } = require("enlisted/ui/hud/state/mission_params.nut")


local teamComps = {
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.winSubtitle", ::ecs.TYPE_STRING],
    ["team.loseSubtitle", ::ecs.TYPE_STRING],
    ["team.deserterSubtitle", ::ecs.TYPE_STRING, ""],
    ["team.winTitle", ::ecs.TYPE_STRING],
  ]
}
local teamsQuery = ::ecs.SqQuery("debriefingTeamQuery", teamComps)

enum STATUS {
  WIN,
  LOSE,
  DESERTER
}

local langsByStatus = {
  [STATUS.WIN]        = { titleLocId = "debriefing/victory", subtitleCompId = "team.winSubtitle"},
  [STATUS.LOSE]       = { titleLocId = "debriefing/defeat", subtitleCompId = "team.loseSubtitle"},
  [STATUS.DESERTER]   = { titleLocId = "debriefing/deserter", subtitleCompId = "team.deserterSubtitle"},
}

/*
    debriefing data should be done on server and send via netMessage
    It is not safe and correct to assume that player can correctly calculate everything by his own data!
    this data can be out of sync, obsolete, not full, etc.
    moreover - it definitely can be full if we are goind to show information about other players in debriefing
    so this code should be moved to game and should become sample where you can find how to correctly get data by player and send it to player
    todo:
      - make per player debriefing event and send it per player from server to player entity
      - killer and players list should have info (enlisted part)
      - listen only to perplayer event

*/
local function getLocalDebriefingAwards() {
  local localKills = localPlayerKills.value
  local localDeaths = localPlayerDeaths.value
  local awards = [{id="kill", value=localKills, subtitle=::loc("debrieifing/subtitles/players", { players = localKills})}]

  local localAwards = localPlayerAwards.value
  local awardTable = {}
  foreach (award in localAwards) {
    if (award.type in awardTable)
      awardTable[award.type].count++
    else
      awardTable[award.type] <- {count = 1}
  }
  foreach (awardName, award in awardTable)
    awards.append({id=awardName, value=award.count})

  if (!localPlayerTeamInfo.value?["team.haveNoSpawn"]) {
    local kdratioDecVals = 2
    local kdRatio = (localDeaths >=0) ? localKills*pow(10,kdratioDecVals)/(localDeaths+1): null
    kdRatio = (kdRatio != null) ? kdRatio.tointeger().tofloat()/pow(10,kdratioDecVals) : null
    if (kdRatio !=null)
      awards.append({id="kills_to_lives" value=kdRatio})
  }
  return awards
}

local function setResult(comp, status) {
  local debriefing = {
    sessionId = get_session_id()
    awards = getLocalDebriefingAwards()
    playerName = remap_nick(localPlayerName.value)
    playerNamePrefixIcon = localPlayerNamePrefixIcon.value
    exitToLobby = true
    missionName = ::loc(missionName.value)

    result = {
      status = status
      title = ::loc(langsByStatus[status].titleLocId)
      subtitle = ::loc(langsByStatus[status].subtitleCompId) ?? ""
      success = status == STATUS.WIN
      fail = status == STATUS.LOSE
      time = get_sync_time()
      who = status == STATUS.WIN ? ::loc(comp["team.winTitle"]) : ""
    }
  }
  debriefingData(debriefing)
}

local function onTeamRoundResult(evt, eid, comp) {
  if (localPlayerTeam.value != comp["team.id"] || debriefingShow.value)
    return
  local status = evt[1] == (evt[0] == comp["team.id"])
    ? STATUS.WIN : STATUS.LOSE
  setResult(comp, status)
}

local function onGetBattleResult(evt, eid, comp) {
  if (debriefingShow.value)
    return
  teamsQuery.perform(
    function(eid, comp) {
      if (localPlayerTeam.value == comp["team.id"])
        setResult(comp, STATUS.DESERTER)
    })
}


::ecs.register_es("roundresult_debriefing_es",
  {[EventTeamRoundResult] = onTeamRoundResult,},
  teamComps
)

::ecs.register_es("deserter_debriefing_es",
  {
    [::ecs.sqEvents.CmdGetBattleResult] = onGetBattleResult,
  },
  { comps_rq = ["player"] })


::console.register_command(function() {
  ::ecs.g_entity_mgr.broadcastEvent(EventTeamRoundResult(localPlayerTeam.value, true))
}, "ui.broadcast_win")

::console.register_command(function() {
  ::ecs.g_entity_mgr.broadcastEvent(EventTeamRoundResult(localPlayerTeam.value, false))
}, "ui.broadcast_defeat")
 