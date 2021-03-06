local {EventZoneCaptured, EventZoneIsAboutToBeCaptured} = require("zoneevents")
local {EventTeamLost} = require("teamevents")
local app = require("net")

local teamComps = {
  comps_rw = [
    ["team.failEndTime", ::ecs.TYPE_FLOAT],
    ["team.squadsCanSpawn", ::ecs.TYPE_BOOL],
  ]
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.score", ::ecs.TYPE_FLOAT],
    ["team.zeroScoreFailTimer", ::ecs.TYPE_FLOAT],
    ["team.squadSpawnCost", ::ecs.TYPE_INT],
  ]
}
local fail_timer
local teamCapturingThePoint = {}

local function checkFailTimer(eid, comp) {
  if (comp["team.zeroScoreFailTimer"] < 0)
    return

  local needTimer = comp["team.score"] <= 0 && (teamCapturingThePoint?[comp["team.id"]].len() ?? 0) == 0
  local isTimerActive = fail_timer != null
  if (needTimer == isTimerActive)
    return

  if (needTimer) {
    fail_timer = function (){
      if (comp["team.score"] <= 0)
        ::ecs.g_entity_mgr.broadcastEvent(EventTeamLost(comp["team.id"]))
      else
        comp["team.failEndTime"] = 0
      fail_timer = null
    }
    ::ecs.set_callback_timer(fail_timer, comp["team.zeroScoreFailTimer"], false)
    local curTime = app.get_sync_time()
    comp["team.failEndTime"] = curTime + comp["team.zeroScoreFailTimer"]
  }
  else {
    comp["team.failEndTime"] = 0
    ::ecs.clear_callback_timer(fail_timer)
    fail_timer = null
  }
}

local checkFailTimerForTeamQuery = ::ecs.SqQuery("checkFailTimerForTeamQuery", teamComps)
local function checkFailTimerForTeam(team) {
  checkFailTimerForTeamQuery.perform(checkFailTimer, "eq(team.id,{0})".subst(team))
}

local function onZoneStartCapture(evt, e, c) {
  if (teamCapturingThePoint?[evt.data.team][evt.data.eid])
    return
  local team = evt.data.team
  if (!(team in teamCapturingThePoint))
    teamCapturingThePoint[team] <- {}
  teamCapturingThePoint[team][evt.data.eid] <- true
  checkFailTimerForTeam(evt.data.team)
}

local function onZoneEndCapture(evt, e, c) {
  if (!teamCapturingThePoint?[evt.data.team][evt.data.eid])
    return
  delete teamCapturingThePoint[evt.data.team][evt.data.eid]
  checkFailTimerForTeam(evt.data.team)
}

local function onZoneCaptured(evt, e, c) {
  local zoneEid = evt[0]
  local team = evt[1]
  if (!teamCapturingThePoint?[team][zoneEid])
    return
  delete teamCapturingThePoint[team][zoneEid]
  checkFailTimerForTeam(team)
}

local function onTeamDestroy(evt, eid, comp) {
  if (comp["team.id"] in teamCapturingThePoint)
    delete teamCapturingThePoint[comp["team.id"]]
  if (fail_timer)
    ::ecs.clear_callback_timer(fail_timer)
  fail_timer = null
}

local function onScoreChange(evt, eid, comp){
  if (comp["team.squadSpawnCost"] > 0)
    comp["team.squadsCanSpawn"] = comp["team.score"] > 0
  checkFailTimer(eid, comp)
}

::ecs.register_es("team_on_zero_spawn_score_es",
  {
    [::ecs.EventComponentChanged] = onScoreChange,
    [::ecs.EventEntityDestroyed] = onTeamDestroy,
  },
  teamComps,
  {tags="server", track = "team.score"}
)

::ecs.register_es("team_zone_monitor_es",
  {
    [::ecs.sqEvents.EventZoneStartCapture] = onZoneStartCapture,
    [::ecs.sqEvents.EventZoneStartDecapture] =  onZoneEndCapture,
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
    [::ecs.sqEvents.EventTeamStartDecapture] = onZoneStartCapture,
    [::ecs.sqEvents.EventTeamEndDecapture] = onZoneEndCapture
  },
  {},
  {tags="server"}
) 