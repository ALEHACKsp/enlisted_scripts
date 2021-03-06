local {TEAM_UNASSIGNED} = require("team")
local { addAward } = require("game/es/awards.nut")
local is_teams_friendly = require("globals/is_teams_friendly.nut")
local { EventPlayerInjuredEntity } = require("damageevents")
local { EventPlayerKilledEntity } = require("deathevents")
local { get_time_msec } = require("dagor.time")
local math = require("math")

const ASSIST_TIME_MSEC = 20000
const ASSIST_DIST = 20
local lastDamage = {}

local function getCrewForAssist(eid) {
  local vehicleEid = ::ecs.get_comp_val(eid, "human_anim.vehicleSelected") ?? INVALID_ENTITY_ID
  if (vehicleEid == INVALID_ENTITY_ID)
    return []
  return (::ecs.get_comp_val(vehicleEid, "vehicle_seats_owners")?.getAll() ?? [])
    .map(@(owner) owner.eid)
    .filter(@(e) e != eid)
}

local enemyMarksQuery = ::ecs.SqQuery("enemyMarksQuery", {
  comps_ro=[
    ["transform", ::ecs.TYPE_MATRIX],
    ["userPointType", ::ecs.TYPE_STRING],
    ["userPointOwner", ::ecs.TYPE_EID]
  ]
})

local function getPlayersThatMarked(victimEid, playerEid, playerTeam, dist) {
  local res = {}
  local victimTransform = ::ecs.get_comp_val(victimEid, "transform")
  if (victimTransform != null) {
    local victimPos = victimTransform.getcol(3)
    enemyMarksQuery.perform(function (_, comp) {
      local eid = comp["userPointOwner"]
      if ((eid == playerEid) || (comp["userPointType"] != "enemy"))
        return
      local team = ::ecs.get_comp_val(eid, "team", TEAM_UNASSIGNED)
      if ((team != TEAM_UNASSIGNED) && !is_teams_friendly(playerTeam, team))
        return
      local markPos = comp["transform"].getcol(3)
      if ((victimPos - markPos).lengthSq() < dist * dist)
        res[eid] <- 1
    })
  }
  return res
}

local function applyAssist(assistPlayerEids) {
  foreach (pEid, cnt in assistPlayerEids) {
    local assists = ::ecs.get_comp_val(pEid, "scoring_player.assists")
    if (assists != null)
      ::ecs.set_comp_val(pEid, "scoring_player.assists", assists + cnt)
  }
}

local function zoneRadius(comp) {
  local sphereRad = comp["sphere_zone.radius"]
  if (sphereRad != null)
    return sphereRad
  local tm = comp["transform"]
  return math.sqrt(tm.getcol(0).lengthSq() + tm.getcol(2).lengthSq()) / 2
}

local defenseZoneQuery = ::ecs.SqQuery("defenseZoneQuery", {
  comps_ro=[
    ["transform", ::ecs.TYPE_MATRIX],
    ["capzone.owningTeam", ::ecs.TYPE_INT],
    ["capzone.defenseRadiusAdd", ::ecs.TYPE_FLOAT],
    ["sphere_zone.radius", ::ecs.TYPE_FLOAT, null]
  ]
})

local function onPlayerOrBotKilledEntity(victimEid, killerEid, playerEid, comp) {
  if (victimEid == killerEid)
    return

  local killerPlayerTeam  = comp.team
  local victimTeam = ::ecs.get_comp_val(victimEid, "team", TEAM_UNASSIGNED)
  if (victimTeam == TEAM_UNASSIGNED || is_teams_friendly(killerPlayerTeam, victimTeam))
    return

  local kills = ::ecs.get_comp_val(killerEid, "squad_member.kills")
  if (kills != null)
    ::ecs.set_comp_val(killerEid, "squad_member.kills", kills + 1)

  local crewForAssist = getCrewForAssist(killerEid)

  if (::ecs.get_comp_val(victimEid, "airplane", null)) {
    comp["scoring_player.planeKills"]++
    addAward(playerEid, "planeKill")
    local awardList = [{ stat = "planeKills", eid = killerEid }]
    awardList.extend(
      crewForAssist.map(@(e) { stat = "crewPlaneKillAssists", eid = e}))
    ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.EventSquadMembersStats(
      { list = awardList }))
    return
  }

  local assistPlayerEids = {}

  if (::ecs.get_comp_val(victimEid, "vehicle", null))
    assistPlayerEids = getPlayersThatMarked(victimEid, playerEid, killerPlayerTeam, ASSIST_DIST)

  if (::ecs.get_comp_val(victimEid, "isTank", null)) {
    comp["scoring_player.tankKills"]++
    addAward(playerEid, "tankKill")
    local awardList = [{ stat = "tankKills", eid = killerEid }]
    awardList.extend(
      crewForAssist.map(@(e) { stat = "crewTankKillAssists", eid = e}))
    ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.EventSquadMembersStats(
      { list = awardList }))
    applyAssist(assistPlayerEids)
    return
  }

  if (victimEid in lastDamage) {
    local lastAssistTime = get_time_msec() - ASSIST_TIME_MSEC
    local assistEids = []
    foreach(pEid, lastTime in lastDamage[victimEid])
      if (lastTime.soldierEid != killerEid && lastTime.time >= lastAssistTime) {
        if (pEid in assistPlayerEids)
          assistPlayerEids[pEid] = assistPlayerEids[pEid] + 1
        else
          assistPlayerEids[pEid] <- 1
        assistEids.append(lastTime.soldierEid)
      }
    if (assistEids.len() > 0)
      ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.EventSquadMembersStats(
        { list = assistEids.map(@(e) { stat = "assists", eid = e }) }))
    delete lastDamage[victimEid]
  }

  applyAssist(assistPlayerEids)

  if (crewForAssist.len() > 0) {
    ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.EventSquadMembersStats(
      { list = crewForAssist.map(@(e) { stat = "crewKillAssists", eid = e}) }))
  }

  local victimPos = ::ecs.get_comp_val(victimEid, "transform")?.getcol(3)
  if (victimPos != null) {
    local isNearFriendlyZone = defenseZoneQuery.perform(function(eid, comp) {
      if (is_teams_friendly(comp["capzone.owningTeam"], killerPlayerTeam)) {
        local zonePos = comp["transform"].getcol(3)
        local defenseRadius = comp["capzone.defenseRadiusAdd"]
        local zoneDefenseRadius = zoneRadius(comp) + defenseRadius
        if ((victimPos - zonePos).lengthSq() < zoneDefenseRadius * zoneDefenseRadius)
          return true
      }
    }) ?? false
    if (isNearFriendlyZone)
      comp["scoring_player.defenseKills"] ++
  }
}

local onPlayerKilledEntity = @(evt, eid, comp)
  onPlayerOrBotKilledEntity(evt[0], evt[1], eid, comp)

local onEventPlayerBotKilledEntity = @(evt, eid, comp)
  onPlayerOrBotKilledEntity(evt.data.victim, evt.data.killer, eid, comp)

local function onPlayerInjuredEntity(evt, eid, comp) {
  local victim = evt[0]
  local offender = evt[1]
  local offenderPlrEid = evt[4]
  if (!(victim in lastDamage))
    lastDamage[victim] <- {}
  lastDamage[victim][offenderPlrEid] <- { time = get_time_msec(), soldierEid = offender }
}

::ecs.register_es("enlisted_kill_award_es",
  {
    [EventPlayerKilledEntity] = onPlayerKilledEntity,
    [::ecs.sqEvents.EventPlayerBotKilledEntity] = onEventPlayerBotKilledEntity,
    [EventPlayerInjuredEntity] = onPlayerInjuredEntity,
  },
  {
    comps_rw = [
      ["scoring_player.tankKills",  ::ecs.TYPE_INT],
      ["scoring_player.planeKills",  ::ecs.TYPE_INT],
      ["scoring_player.defenseKills",  ::ecs.TYPE_INT],
    ]

    comps_ro = [
      ["userid", ::ecs.TYPE_INT64],
      ["team", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
    ]
  },
  {tags="server"}
)


local function onSquadAliveChange(evt, eid, comp) {
  if (comp["squad.numAliveMembers"] > 0)
    return

  local playerEid = comp["squad.ownerPlayer"]
  local prevVal = ::ecs.get_comp_val(playerEid, "scoring_player.squadDeaths")
  if (prevVal != null)
    ::ecs.set_comp_val(playerEid, "scoring_player.squadDeaths", prevVal + 1)
}

::ecs.register_es("squad_death_es", {
    onChange = onSquadAliveChange
  },
  {
    comps_track = [["squad.numAliveMembers", ::ecs.TYPE_INT]],
    comps_ro = [["squad.ownerPlayer", ::ecs.TYPE_EID]],
  },
  {tags = "server"}
) 