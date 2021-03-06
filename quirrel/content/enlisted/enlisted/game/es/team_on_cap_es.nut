local {EventTeamLost} = require("teamevents")
local {EventZoneCaptured, EventZoneIsAboutToBeCaptured} = require("zoneevents")
local checkZonesGroup = require("zone_cap_group.nut").allZonesInGroupCapturedByTeam
local {TEAM_UNASSIGNED} = require("team")

local onZoneCapQuery = ::ecs.SqQuery("onZoneCapQuery", {comps_ro = [["team.id", ::ecs.TYPE_INT], ["team.score", ::ecs.TYPE_FLOAT], ["team.scoreCap", ::ecs.TYPE_FLOAT]]})
local function onZoneCaptured(evt, eid, comp) {
  local teamId = evt[1]
  local teamCapPen = comp["team.capturePenalty"]
  local capPen = ::ecs.get_comp_val(evt[0], "capzone.capPenalty", teamCapPen)
  local checkAllZonesInGroup = ::ecs.get_comp_val(evt[0], "capzone.checkAllZonesInGroup", false)
  local zonesMustBeCapturedByTeam = ::ecs.get_comp_val(evt[0], "capzone.mustBeCapturedByTeam", TEAM_UNASSIGNED)
  local zoneGroupName = ::ecs.get_comp_val(evt[0], "groupName", -1)
  if (checkAllZonesInGroup && (teamId != zonesMustBeCapturedByTeam || !checkZonesGroup(evt[0], teamId, zoneGroupName)))
    return
  if (comp["team.id"] != teamId && capPen != 0) {
    if (capPen >= comp["team.score"]) {
      comp["team.score"] = 0
      ::ecs.g_entity_mgr.broadcastEvent(EventTeamLost(comp["team.id"]))
    }
    else
      comp["team.score"] -= capPen
  }

  local capReward = ::ecs.get_comp_val(evt[0], "capzone.capReward", 0.0)
  if (comp["team.id"] == teamId && capReward != 0) {
    local capRewardPartCap = ::ecs.get_comp_val(evt[0], "capzone.capRewardPartCap", 10000.0)
    local minEnemyTeamTicketsPart = 1.0
    onZoneCapQuery.perform(
        function(eid, comp) {
          local part = comp["team.score"] / comp["team.scoreCap"]
          minEnemyTeamTicketsPart = ::min(part, minEnemyTeamTicketsPart)
        },"ne(team.id,{0})".subst(teamId))
    local scoreCap = comp["team.scoreCap"] * ::min(1.0, minEnemyTeamTicketsPart * capRewardPartCap)
    comp["team.score"] = comp["team.score"] + ::max(::min(capReward, scoreCap - comp["team.score"]), 0.0)
  }
}

::ecs.register_es("team_on_cap_es",
  {
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
  },
  {
    comps_rw = [
      ["team.score", ::ecs.TYPE_FLOAT],
    ]

    comps_ro = [
      ["team.id", ::ecs.TYPE_INT],
      ["team.capturePenalty", ::ecs.TYPE_FLOAT],
      ["team.scoreCap", ::ecs.TYPE_FLOAT, 0],
    ]
  },
  {tags = "server"}
)


 