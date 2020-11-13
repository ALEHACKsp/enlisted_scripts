local { TEAM_UNASSIGNED } = require("team")
local {addAward} = require("game/es/awards.nut") // TODO: move to separate module (although there's no need in it right now)
local {get_team_eid} = require("globals/common_queries.nut")
local {EventZoneIsAboutToBeCaptured, EventZoneDeactivated, EventZoneCaptured, EventZoneDecaptured,
  EventCapZoneLeave, EventCapZoneEnter} = require("zoneevents")
local {logerr} = require("dagor.debug")


const CAPSCORES_CAPTURE_FINAL = 1.0
const CAPSCORES_CAPTURE_PARTICIPATE = 0.5

local capStatus = {
  DECAPTURE = 2
  CAPTURE = 1
  UNKNOWN = 0
}

local MULTIPLE_TEAMS = -2 // a magic number to show that there is more than one team on zone.


local function startCap(zone_eid, comp, team) {
  ::ecs.clear_timer({eid=zone_eid, id="capzone"})
  comp["capzone.capTeam"] = team
  comp["capzone.capTeamEid"] = get_team_eid(team) ?? INVALID_ENTITY_ID
  comp["capzone.captureStatus"] = capStatus.CAPTURE
  ::ecs.set_timer({eid=zone_eid, id="capzone", interval=comp["capzone.timerPeriod"], repeat=true})
  ::ecs.server_broadcast_net_sqevent(::ecs.event.EventZoneStartCapture({eid=zone_eid, team=team}))
}


local function startDecap(zone_eid, comp, prev_capturing_team, capturing_team) {
  ::ecs.clear_timer({eid=zone_eid, id="capzone"})
  local team = comp["capzone.capTeam"]
  if (team == TEAM_UNASSIGNED && !comp["capzone.decapOnNeutral"]) {
    comp["capzone.progress"]= 0.0
    comp["capzone.capTeam"] = TEAM_UNASSIGNED
    comp["capzone.captureStatus"]=capStatus.UNKNOWN
    comp["capzone.owningTeam"] = TEAM_UNASSIGNED
  }
  else {
    ::ecs.set_timer({eid=zone_eid, id="capzone", interval=comp["capzone.timerPeriod"], repeat=true})
    comp["capzone.captureStatus"]=capStatus.DECAPTURE
    ::ecs.server_broadcast_net_sqevent(::ecs.event.EventZoneStartDecapture({eid=zone_eid, team=team}))
    if (prev_capturing_team != capturing_team) {
      if ((prev_capturing_team > 0) && (team != prev_capturing_team))
        ::ecs.server_broadcast_net_sqevent(::ecs.event.EventTeamEndDecapture({eid=zone_eid, team=prev_capturing_team}))
      if (capturing_team > 0)
        ::ecs.server_broadcast_net_sqevent(::ecs.event.EventTeamStartDecapture({eid=zone_eid, team=capturing_team}))
    }
  }
}

local function onTeamDominateZone(zone_eid, comp, team) {
  local capTeam = comp["capzone.capTeam"]
  local curProgress = comp["capzone.progress"]
  if (capTeam == team || capTeam == TEAM_UNASSIGNED) {
    if (curProgress < 1.0) {
      startCap(zone_eid, comp, team)
      comp["capzone.curTeamCapturingZone"] = team
    }
  }
  else if (curProgress > 0.0) {
    startDecap(zone_eid, comp, comp["capzone.curTeamCapturingZone"], team)
    comp["capzone.curTeamCapturingZone"] = team
  }
  else {
    startCap(zone_eid, comp, team)
    comp["capzone.curTeamCapturingZone"] = team
  }
}

local function onZoneTieOrNeutral(zone_eid, comp, numTeamsPresent) {
  local prevCapturingTeam = comp["capzone.curTeamCapturingZone"];
  comp["capzone.curTeamCapturingZone"] = (numTeamsPresent > 1) ? MULTIPLE_TEAMS : TEAM_UNASSIGNED
  local curProgress = comp["capzone.progress"]
  if (curProgress > 0.0 && curProgress < 1.0) {
    ::ecs.clear_timer({eid=zone_eid, id="capzone"})
    if (comp["capzone.autoDecap"] || (comp["capzone.owningTeam"] == TEAM_UNASSIGNED && comp["capzone.autoCap"]))
      startDecap(zone_eid, comp, prevCapturingTeam, comp["capzone.curTeamCapturingZone"])
    else if (comp["capzone.autoCap"])
      startCap(zone_eid, comp, comp["capzone.owningTeam"])
  }
}

local function onTeamPresenceChanged(zone_eid, comp) {
  if (!comp.active)
    return

  local gap = comp["capzone.presenceAdvantageToDominate"]
  local numTeamsPresent = 0
  local dominatingTeam = TEAM_UNASSIGNED
  local maxPresenceNum = 1 - gap
  local advantage = 0
  foreach (tid, team in comp["teamPresence"]) {
    local teamPresenceNum = team.len()
    if (teamPresenceNum > 0) {
      if (teamPresenceNum >= maxPresenceNum + gap) {
        dominatingTeam = tid.tointeger()
      } else if (teamPresenceNum > maxPresenceNum - gap) {
        dominatingTeam = MULTIPLE_TEAMS
      }
      if (teamPresenceNum > maxPresenceNum) {
        advantage = max(0, teamPresenceNum - (maxPresenceNum + gap - 1))
        maxPresenceNum = teamPresenceNum
      } else {
        advantage = clamp(maxPresenceNum - (teamPresenceNum + gap - 1), 0, advantage)
      }
      numTeamsPresent++
    }
  }
  comp["capzone.capTeamAdvantage"] = advantage
  comp["capzone.isMultipleTeamsPresent"] = numTeamsPresent > 1

  local onlyTeamCanCap = comp["capzone.onlyTeamCanCapture"]
  local allowDecap = comp["capzone.allowDecap"]
  local curProgress = comp["capzone.progress"]
  local isNumberDomination = comp["capzone.canCaptureByPresenceDomination"]

  local isTeamDominating = numTeamsPresent == 1 || (isNumberDomination && dominatingTeam >= 0)
  local isTeamCanCapture = (onlyTeamCanCap == TEAM_UNASSIGNED || onlyTeamCanCap == dominatingTeam || (allowDecap && curProgress == 1.0))

  if (isTeamDominating && isTeamCanCapture)
    onTeamDominateZone(zone_eid, comp, dominatingTeam)
  else
    onZoneTieOrNeutral(zone_eid, comp, numTeamsPresent)
}

local function awardPlayer(playerEid) {
  if (playerEid != INVALID_ENTITY_ID)
    addAward(playerEid, "capture")
}

local function getVisitorPlayerEid(visitorEid) { //get squad.ownerPlayer of hero or bot by squad
  local squadEid = ::ecs.get_comp_val(visitorEid, "squad_member.squad") ?? INVALID_ENTITY_ID
  return ::ecs.get_comp_val(squadEid, "squad.ownerPlayer") ?? INVALID_ENTITY_ID
}

local playerCapturesQuerry = ::ecs.SqQuery("playerCapturesQuerry",
  { comps_rw = [["scoring_player.captures", ::ecs.TYPE_INT]], comps_ro = [["team", ::ecs.TYPE_INT]] })


local getSoldierData = @(eid, teamId = TEAM_UNASSIGNED) {
  eid = eid
  squadEid = ::ecs.get_comp_val(eid, "squad_member.squad") ?? INVALID_ENTITY_ID
  guid = ::ecs.get_comp_val(eid, "guid") ?? ""
  teamId = teamId
}

local function awardZoneCapturers(comp) {
  local awardPlayers = {} //eid = bool, true - was at capture end, or has bot on capture end
  local awardSoldiers = [] //award only soldiers who was on point when capture finish
  foreach(eid in comp["capzone.capturersEids"]) {
    local teamId = ::ecs.get_comp_val(eid, "team", TEAM_UNASSIGNED)
    if (teamId == comp["capzone.owningTeam"])
      awardPlayers[eid] <- false
  }
  foreach(s in comp["capzone.soldiersCapture"].getAll())
    if (s.teamId == comp["capzone.owningTeam"])
      awardSoldiers.append(s.__merge({ stat = "captures", amount = CAPSCORES_CAPTURE_PARTICIPATE }))

  foreach (tid, team in comp["teamPresence"])
    foreach (eid in team) {
      local playerEid = getVisitorPlayerEid(eid)
      if (playerEid != INVALID_ENTITY_ID)
        awardPlayers[playerEid] <- true

      local sData = getSoldierData(eid)
      local awardData = awardSoldiers.findvalue(@(s) s.guid == sData.guid && s.squadEid == sData.squadEid)
      if (awardData != null)
        awardData.amount = CAPSCORES_CAPTURE_FINAL
    }

  foreach(playerEid, isFinal in awardPlayers)
    if (isFinal)
      awardPlayer(playerEid)

  playerCapturesQuerry.perform(function(pEid, pComp) {
    if ((pEid in awardPlayers) && comp["capzone.owningTeam"] == pComp.team)
      pComp["scoring_player.captures"] += awardPlayers[pEid]
        ? CAPSCORES_CAPTURE_FINAL : CAPSCORES_CAPTURE_PARTICIPATE
  })

  ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.EventSquadMembersStats({ list = awardSoldiers }))
  comp["capzone.capturersEids"].clear()
  comp["capzone.soldiersCapture"] = {}
}

local function getAdvantageSpeedMult(canCaptureByPresenceDomination, advantage, isEnemyPresent, advantageDivisor) {
  if (!canCaptureByPresenceDomination || advantageDivisor <= 0)
    return 1.0
  local mult = advantage / advantageDivisor
  if (!isEnemyPresent && mult < 1.0)
    mult = 1.0
  return mult
}

local getMinCapDecapSpeedMult = @(advantageDivisor) advantageDivisor > 0.0 ? 1.0 / advantageDivisor : 1.0

local deactivationTimer = null
local deactivationCallback = null

local function onCapTimer(evt, zone_eid, comp) {
  local progress = comp["capzone.progress"]
  local capTeamEid = comp["capzone.capTeamEid"]
  local capSpeedMult = ::ecs.get_comp_val(capTeamEid, "team.captureSpeedMult", 1.0)
  local advantageMult = getAdvantageSpeedMult(comp["capzone.canCaptureByPresenceDomination"], comp["capzone.capTeamAdvantage"],
                                              comp["capzone.isMultipleTeamsPresent"], comp["capzone.advantageDivisor"])
  local minCapSpeedMult = getMinCapDecapSpeedMult(comp["capzone.advantageDivisor"])
  local maxCapSpeedMult = comp["capzone.maxCapDecapSpeedMult"]
  local capSpeed = (1.0 / comp["capzone.capTime"]) * clamp(capSpeedMult * advantageMult, minCapSpeedMult, maxCapSpeedMult)
  local progressDelta = capSpeed * comp["capzone.timerPeriod"]

//  if (progress < 0.5 && progress + progressDelta >= 0.5)
//    ::ecs.server_broadcast_net_sqevent(::ecs.event.EventZoneHalfCaptured({eid=zone_eid, team=comp["capzone.capTeam"]}))

  if (progress + progressDelta >= 1.0) {
    comp["capzone.progress"] = 1.0
    comp["capzone.captureStatus"] = capStatus.UNKNOWN

    if (comp["capzone.deactivateAfterCap"] && !comp["capzone.checkAllZonesInGroup"])
      comp["active"] = false // forcefully deactivate, so nobody will be able to push any events to it

    local reCap = comp["capzone.owningTeam"] == comp["capzone.capTeam"]
    local deactivateAfterTimeout = comp["capzone.deactivateAfterTimeout"]
    if (deactivateAfterTimeout > 0.0) {
      if (comp["capzone.owningTeam"] != comp["capzone.capTeam"]) {
        local capTeam = comp["capzone.capTeam"]

        ::ecs.g_entity_mgr.broadcastEvent(EventZoneIsAboutToBeCaptured(zone_eid, capTeam))

        local respawnBaseEid = comp["capzone.respawnBaseEid"]
        deactivationCallback = function () {
          deactivationTimer = null
          ::ecs.g_entity_mgr.broadcastEvent(EventZoneDeactivated(zone_eid, capTeam))
          ::ecs.g_entity_mgr.destroyEntity(respawnBaseEid)
        }
        deactivationTimer = ::ecs.set_callback_timer(deactivationCallback, deactivateAfterTimeout, false)
      }
    }
    else if (comp["capzone.owningTeam"] != comp["capzone.capTeam"])
      ::ecs.g_entity_mgr.broadcastEvent(EventZoneCaptured(zone_eid, comp["capzone.capTeam"]))

    comp["capzone.owningTeam"] = comp["capzone.capTeam"]
    if (!reCap)
      awardZoneCapturers(comp)
  }
  else
    comp["capzone.progress"] = progress + progressDelta
}


local function onDecapTimer(evt, zone_eid, comp) {
  local progress = comp["capzone.progress"]
  local team = comp["capzone.capTeam"]
  if (progress == 1.0 && comp["capzone.autoDecap"]) {
    ::print($"zone {zone_eid} decaptured(1)")
    ::ecs.g_entity_mgr.broadcastEvent(EventZoneDecaptured(zone_eid, team))
  }
  local advantageMult = getAdvantageSpeedMult(comp["capzone.canCaptureByPresenceDomination"], comp["capzone.capTeamAdvantage"],
                                              comp["capzone.isMultipleTeamsPresent"], comp["capzone.advantageDivisor"])
  local minDecapSpeedMult = getMinCapDecapSpeedMult(comp["capzone.advantageDivisor"])
  local maxDecapSpeedMult = comp["capzone.maxCapDecapSpeedMult"]
  local decapSpeed = (1.0 / comp["capzone.decapTime"]) * clamp(advantageMult, minDecapSpeedMult, maxDecapSpeedMult)
  local progressDelta = decapSpeed * comp["capzone.timerPeriod"]
  if (progressDelta >= progress) {
    comp["capzone.progress"] = 0.0
    comp["capzone.capTeam"]= TEAM_UNASSIGNED
    comp["capzone.captureStatus"] = capStatus.UNKNOWN
    if (!comp["capzone.autoDecap"])
      ::ecs.g_entity_mgr.broadcastEvent(EventZoneDecaptured(zone_eid, comp["capzone.owningTeam"]))
    comp["capzone.owningTeam"] = TEAM_UNASSIGNED
    local capTeam = comp["capzone.curTeamCapturingZone"]
    if (capTeam > 0)
      ::ecs.server_broadcast_net_sqevent(::ecs.event.EventTeamEndDecapture({eid=zone_eid, team=capTeam}))
    onTeamPresenceChanged(zone_eid, comp)
  }
  else
    comp["capzone.progress"]=progress - progressDelta
}


local function onTimer(evt, zone_eid, comp) {
  if (comp["capzone.captureStatus"] == capStatus.CAPTURE)
    onCapTimer(evt, zone_eid, comp)
  else if (comp["capzone.captureStatus"] == capStatus.DECAPTURE)
    onDecapTimer(evt, zone_eid, comp)
  else
    ::ecs.clear_timer({eid=zone_eid, id="capzone"})
}


local function addZonePlayerPresence(visitorEid, comp) {
  local playerEid = getVisitorPlayerEid(visitorEid)
  if (playerEid == INVALID_ENTITY_ID)
    return
  local teamId = ::ecs.get_comp_val(visitorEid, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED || teamId == comp["capzone.owningTeam"])
    return

  if (comp["capzone.capturersEids"].indexof(playerEid, ::ecs.TYPE_EID) == null)
    comp["capzone.capturersEids"].append(playerEid, ::ecs.TYPE_EID)

  local sData = getSoldierData(visitorEid, teamId)
  local hasSoldier = false
  foreach(s in comp["capzone.soldiersCapture"])
    if (s.guid == sData.guid && s.squadEid == sData.squadEid) {
      hasSoldier = true
      break
    }

  if (!hasSoldier)
    comp["capzone.soldiersCapture"][visitorEid.tostring()] = sData
}


local function onZoneEnter(evt, zone_eid, comp) {
  local visitor = evt[0]
  addZonePlayerPresence(visitor, comp)
  local teamId = ::ecs.get_comp_val(visitor, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED)
    return
  teamId = teamId.tostring()
  local teamPresence = comp["teamPresence"]
  if (teamId in teamPresence) {
    teamPresence[teamId].append(visitor)
  }
  else
    teamPresence[teamId] <- [visitor]
  onTeamPresenceChanged(zone_eid, comp)
}

local function onZoneLeave(evt, zone_eid, comp) {
  local visitor = evt[0]
  local teamId = ::ecs.get_comp_val(visitor, "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED)
    return
  teamId = teamId.tostring()
  local teamPresence = comp["teamPresence"]
  if (teamId in teamPresence) {
    local idx = teamPresence[teamId].indexof(visitor)
    if (idx != null)
      teamPresence[teamId].remove(idx)
  }
  else
    teamPresence[teamId] <- [] // reset to zero
  onTeamPresenceChanged(zone_eid, comp)
}


local function onZoneActivate(evt, zone_eid, comp) {
  if (evt.data["activate"])
    onTeamPresenceChanged(zone_eid, comp)
  else
    ::ecs.clear_timer({eid=zone_eid, id="capzone"})
}

local function onZoneChange(evt, comp, def, count) {
  local teamId = ::ecs.get_comp_val(evt[0], "team", TEAM_UNASSIGNED)
  if (teamId == TEAM_UNASSIGNED)
    return
  teamId = teamId.tostring()
  local presenceTeamCount = comp["capzone.presenceTeamCount"]
  if (teamId in presenceTeamCount)
    presenceTeamCount[teamId] += count
  else
    presenceTeamCount[teamId] <- def
}

/*
teampresence :
{
  "1" = {"0"="eid1", "1"="eid2"}, where "1" is team.id
  "2" = {"0"="eid1", "1"="eid2"},
}
There is no way to have arrays in objects currently, so it seems weird and not optimal
However this is still important, cause we now can have hot reload for capzone
*/

local comps = {
  comps_rw = [
    ["capzone.capTeam", ::ecs.TYPE_INT],
    ["capzone.owningTeam", ::ecs.TYPE_INT],
    ["capzone.capTeamEid", ::ecs.TYPE_EID],
    ["capzone.curTeamCapturingZone", ::ecs.TYPE_INT],
    ["teamPresence", ::ecs.TYPE_OBJECT],
    ["capzone.captureStatus", ::ecs.TYPE_INT],
    ["capzone.isMultipleTeamsPresent", ::ecs.TYPE_BOOL],
    ["capzone.progress", ::ecs.TYPE_FLOAT],
    ["active", ::ecs.TYPE_BOOL],
    ["capzone.capturersEids", ::ecs.TYPE_EID_LIST],
    ["capzone.soldiersCapture", ::ecs.TYPE_OBJECT],
    ["capzone.capTeamAdvantage", ::ecs.TYPE_INT],
  ]
  comps_ro = [
    ["capzone.onlyTeamCanCapture", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["capzone.allowDecap", ::ecs.TYPE_BOOL, false],
    ["capzone.capTime", ::ecs.TYPE_FLOAT, 20.0],
    ["capzone.decapTime", ::ecs.TYPE_FLOAT, 30.0],
    ["capzone.timerPeriod", ::ecs.TYPE_FLOAT, 1.0/3.0],
    ["capzone.deactivateAfterCap",::ecs.TYPE_BOOL, false],
    ["capzone.checkAllZonesInGroup",::ecs.TYPE_BOOL, false],
    ["capzone.decapOnNeutral",::ecs.TYPE_BOOL, false],
    ["capzone.autoDecap",::ecs.TYPE_BOOL, true],
    ["capzone.autoCap",::ecs.TYPE_BOOL, true],
    ["capzone.deactivateAfterTimeout", ::ecs.TYPE_FLOAT, -1.0],
    ["capzone.respawnBaseEid", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["capzone.presenceAdvantageToDominate", ::ecs.TYPE_INT, 1],
    ["capzone.canCaptureByPresenceDomination", ::ecs.TYPE_BOOL, false],
    ["capzone.advantageDivisor", ::ecs.TYPE_FLOAT, 4.0],
    ["capzone.maxCapDecapSpeedMult", ::ecs.TYPE_FLOAT, 2.0],
  ]
}

::ecs.register_es("capzone_es", {
  [EventCapZoneEnter] = onZoneEnter,
  [EventCapZoneLeave] = onZoneLeave,
  [::ecs.sqEvents.EventEntityActivate] = onZoneActivate,
  Timer = onTimer,
}, comps, {tags="server"})

::ecs.register_es("capzone_change_es", {
  [EventCapZoneEnter] = @(evt, _, comp) onZoneChange(evt, comp, 1, 1),
  [EventCapZoneLeave] = @(evt, _, comp) onZoneChange(evt, comp, 0, -1)
},
{
  comps_rw = [["capzone.presenceTeamCount", ::ecs.TYPE_OBJECT]]
}, {tags="server"})

::ecs.register_es("capzone_first_enter_es", {
  [EventCapZoneEnter] = function(evt, eid, comp) {
    local visitor = evt[0]
    local team = ::ecs.get_comp_val(visitor, "team", TEAM_UNASSIGNED)
    if (team != TEAM_UNASSIGNED && comp["capzone.onlyTeamCanCapture"] == team) {
      if (comp["capzone.respawnBaseEid"] != INVALID_ENTITY_ID) {
        ::ecs.g_entity_mgr.destroyEntity(comp["capzone.respawnBaseEid"])
        comp["capzone.respawnBaseEid"] = INVALID_ENTITY_ID
      }
      if (deactivationTimer) {
        ::ecs.clear_callback_timer(deactivationTimer)
        deactivationCallback()
      }
    }
  }
},
{
  comps_rw=[["capzone.respawnBaseEid", ::ecs.TYPE_EID]]
  comps_ro=[["capzone.onlyTeamCanCapture", ::ecs.TYPE_INT], ["capzone.capTeam", ::ecs.TYPE_INT]]
  comps_rq=["capzone.deactivateAfterTimeout"]
},
{tags="server"})

local createRespawnBase = @(templ, transform, groupName, team) ::ecs.g_entity_mgr.createEntity(templ, {
  active = true
  transform = transform
  groupName = groupName
  team = team
})

::ecs.register_es("capzone_create_respbase_es", {
  [["onInit", "onChange"]] = function(evt, eid, comp) {
    local spawnAtZoneTimeout = comp["capzone.spawnAtZoneTimeout"]
    if (!comp.active || spawnAtZoneTimeout <= 0.0)
      return
    local templName = comp["capzone.createRespawnBase"]
    local team = comp["capzone.createRespawnBaseForTeam"]
    if (team == TEAM_UNASSIGNED) {
      logerr("capzone.createRespawnBaseForTeam must be set in the mission. Or capzone.spawnAtZoneTimeout must be removed.")
      return
    }
    if (comp["capzone.respawnBaseEid"] != INVALID_ENTITY_ID)
      ::ecs.g_entity_mgr.destroyEntity(comp["capzone.respawnBaseEid"])
    comp["capzone.respawnBaseEid"] = createRespawnBase($"{templName}+temporary_respawn_base", comp.transform, comp.groupName, team)
    local tmpRespawnBase = comp["capzone.respawnBaseEid"]
    ::ecs.set_callback_timer(@() ::ecs.g_entity_mgr.destroyEntity(tmpRespawnBase), spawnAtZoneTimeout, false)
  },
  [EventZoneIsAboutToBeCaptured] = function(evt, eid, comp) {
    local zoneEid = evt[0]
    local capTeam = evt[1]
    if (eid != zoneEid)
      return
    if (comp["capzone.respawnBaseEid"] != INVALID_ENTITY_ID)
      ::ecs.g_entity_mgr.destroyEntity(comp["capzone.respawnBaseEid"])
    comp["capzone.respawnBaseEid"] = createRespawnBase(comp["capzone.createRespawnBase"], comp.transform, comp.groupName, capTeam)
  }
},
{
  comps_track=[["active", ::ecs.TYPE_BOOL]]
  comps_rw=[["capzone.respawnBaseEid", ::ecs.TYPE_EID]]
  comps_ro=[
    ["transform", ::ecs.TYPE_MATRIX],
    ["groupName", ::ecs.TYPE_STRING],
    ["capzone.onlyTeamCanCapture", ::ecs.TYPE_INT],
    ["capzone.createRespawnBase", ::ecs.TYPE_STRING],
    ["capzone.createRespawnBaseForTeam", ::ecs.TYPE_INT],
    ["capzone.spawnAtZoneTimeout", ::ecs.TYPE_FLOAT],
  ]
},
{tags="server"})

::ecs.register_es("capzone_deactivate_temporary_respbase_es", {
  onChange = function(evt, eid, comp) {
    if (!comp.active && deactivationTimer) {
      ::ecs.clear_callback_timer(deactivationTimer)
      deactivationCallback()
    }
  }
},
{
  comps_track=[["active", ::ecs.TYPE_BOOL]]
  comps_rq=["temporaryRespawnbase"]
},
{tags="server"})
 