local {EventZoneCaptured, EventZoneIsAboutToBeCaptured, EventZoneDecaptured} = require("zoneevents")
local {EventTeamLowScore, EventTeamLoseHalfScore, EventTeamLost} = require("teamevents")

local function decScore(comp, amount) {
  local curScore = comp["team.score"]
  local scoreCap = comp["team.scoreCap"]

  if (scoreCap > 0) {
    local prevScore = curScore / scoreCap.tofloat()
    local newScore = (curScore - amount) / scoreCap.tofloat()

    if (newScore <= 0.5 && prevScore > 0.5)
      ::ecs.g_entity_mgr.broadcastEvent(EventTeamLoseHalfScore(comp["team.id"]))
    else if (newScore <= 0.2 && prevScore > 0.2)
      ::ecs.g_entity_mgr.broadcastEvent(EventTeamLowScore(comp["team.id"]))
  }

  comp["team.score"] = ::max(curScore - amount, 0.0)
  if (comp["team.score"] == 0.0){
    comp["score_bleed.domBleedOn"] = false
    if (comp["team.zeroScoreFailTimer"] < 0)
      ::ecs.g_entity_mgr.broadcastEvent(EventTeamLost(comp["team.id"]))
  }
}

local scoring_cz_comps_update = {
  comps_rw = [
    ["team.score", ::ecs.TYPE_FLOAT],
  ],
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.scoreCap", ::ecs.TYPE_FLOAT, 0.0],
    ["score_bleed.staticBleed", ::ecs.TYPE_FLOAT, 0.0],
    ["score_bleed.domBleed", ::ecs.TYPE_FLOAT, 0.0],
    ["score_bleed.domBleedOn", ::ecs.TYPE_BOOL, false],
    ["score_bleed.totalDomBleedMul", ::ecs.TYPE_FLOAT, 1.0],
    ["score_bleed.totalDomBleedOn", ::ecs.TYPE_BOOL, false],
    ["team.zeroScoreFailTimer", ::ecs.TYPE_FLOAT, -1.0],
  ]
}
local function onUpdate(dt, eid, comp){
  if (comp["team.score"] == 0.0)
    return
  if (comp["score_bleed.staticBleed"] > 0)
    decScore(comp, dt*comp["score_bleed.staticBleed"])
  if (comp["score_bleed.domBleed"] > 0 && comp["score_bleed.domBleedOn"]) {
    local domBleed = comp["score_bleed.domBleed"]
    if (comp["score_bleed.totalDomBleedOn"])
      domBleed *= comp["score_bleed.totalDomBleedMul"]
    decScore(comp, dt*domBleed)
  }
}
::ecs.register_es(
  "scoring_cz_update_es",
  { onUpdate = onUpdate },
  scoring_cz_comps_update,
  { updateInterval = 1.0, tags="server", before="team_capzone_es", after="*" }
)


local findBleedQuery = ::ecs.SqQuery("findBleedQuery", {
  comps_rw = [
    ["score_bleed.domBleedOn", ::ecs.TYPE_BOOL],
    ["score_bleed.totalDomBleedOn", ::ecs.TYPE_BOOL]
  ],
  comps_ro = [
    ["team.id", ::ecs.TYPE_INT],
    ["team.numZonesCaptured", ::ecs.TYPE_INT],
    ["score_bleed.domBleed", ::ecs.TYPE_FLOAT],
    ["score_bleed.totalDomZoneCount", ::ecs.TYPE_INT, -1],
    ["score_bleed.totalDomBleedMul", ::ecs.TYPE_FLOAT, 1.0]
  ]
})

local calcMaxZoneQuery = ::ecs.SqQuery("calcMaxZoneQuery", {comps_ro = [["team.numZonesCaptured", ::ecs.TYPE_INT], ["team.id", ::ecs.TYPE_INT]]})
local function onZonesCapChanged(evt, eid, comp) {
  local maxZonesCap = 0
  calcMaxZoneQuery.perform(function(eid, comp) {
    if (comp["team.numZonesCaptured"] > maxZonesCap)
      maxZonesCap = comp["team.numZonesCaptured"]
  })

  findBleedQuery.perform(function(eid, comp) {
    comp["score_bleed.domBleedOn"] = comp["team.numZonesCaptured"] < maxZonesCap && comp["score_bleed.domBleed"] > 0
    comp["score_bleed.totalDomBleedOn"] = comp["score_bleed.totalDomZoneCount"] == maxZonesCap && comp["score_bleed.domBleed"] > 0
  })
}

::ecs.register_es("team_capzone_changed_es", {
      [::ecs.EventComponentChanged] = onZonesCapChanged,
  },
  {comps_track = [["team.numZonesCaptured", ::ecs.TYPE_INT]]},
  {tags="server"}
)

local function onZoneCaptured(evt, eid, comp) {
  local teamId = evt[1]
  if (comp["team.id"] == teamId)
    comp["team.numZonesCaptured"] += 1
}

local function onZoneDecaptured(evt, eid, comp) {
  local teamId = evt[1]
  if (comp["team.id"] == teamId)
    comp["team.numZonesCaptured"] -= 1
}

::ecs.register_es("team_capzone_es", {
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
    [EventZoneDecaptured] = onZoneDecaptured,
  },
  {
    comps_rw = [["team.numZonesCaptured", ::ecs.TYPE_INT],],
    comps_ro = [["team.id", ::ecs.TYPE_INT],]
  },
  {tags="server"}
)

 