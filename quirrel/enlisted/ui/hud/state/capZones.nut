local { TEAM_UNASSIGNED, FIRST_GAME_TEAM } = require("team")
local { isEqual } = require("std/underscore.nut")
local {localPlayerTeamInfo} = require("enlisted/ui/hud/state/teams.nut")
local {localPlayerTeam} = require("ui/hud/state/local_player.nut")
local {EventHeroChanged} = require("gameevents")
local {EventZoneIsAboutToBeCaptured, EventZoneCaptured, EventCapZoneEnter, EventCapZoneLeave} = require("zoneevents")
local {controlledHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {playerEvents} = require("ui/hud/state/eventlog.nut")
local {showMinorCaptureZoneEventsInHud, showMajorCaptureZoneEventsInHud} = require("enlisted/globals/wipFeatures.nut")
local {allZonesInGroupCapturedByTeam, getLastGroupToCaptureByTeam} = require("enlisted/game/es/zone_cap_group.nut")
local {is_entity_in_zone} = require("ecs.utils")

local capZones = persist("capZones", @() ::Watched({}))
local activeCapZonesEids = ::Watched({})
local visibleZoneGroups = ::Watched({})
local whichTeamAttack = ::Computed(@()
  capZones.value.reduce(@(team, zone) zone.active ? zone.only_team_cap : team, -1))


local getSortedZoneEids = @(zones)
  zones.sort(@(a, b) a.ui_order <=> b.ui_order || a.title <=> b.title)
    .map(@(z) z.eid)

local function updateEids() {
  local eids = capZones.value.map(@(z) z.active)
    .filter(@(v) v)
  if (!isEqual(eids, activeCapZonesEids.value))
    activeCapZonesEids(eids)

  local visible = []
  local groups = {}
  foreach (eid, zone in capZones.value)
    if (zone.active || zone.wasActive || zone.alwaysShow) {
      visible.append(zone)
      local groupId = zone?.groupName ?? ""
      if (!(groupId in groups))
        groups[groupId] <- { zones = [], ui_order = zone.ui_order }
      local group = groups[groupId]
      group.zones.append(zone)
      group.ui_order = ::min(group.ui_order, zone.ui_order)
    }
  local groupsSorted = groups.len() == visible.len()
    ? [getSortedZoneEids(visible)]
    : groups.values()
        .sort(@(a, b) a.ui_order <=> b.ui_order)
        .map(@(g) getSortedZoneEids(g.zones))

  if (!isEqual(groupsSorted, visibleZoneGroups.value))
    visibleZoneGroups(groupsSorted)
}
capZones.subscribe(@(_) updateEids())
updateEids()


local function playEvent(e, major=false){
  if (e==null)
    return
  if ((major && showMajorCaptureZoneEventsInHud) || showMinorCaptureZoneEventsInHud)
    playerEvents.pushEvent(e)
}
local playMajorEvent = @(e) playEvent(e, true)
local playMinorEvent = @(e) playEvent(e, false)

local attr2gui = { //it is much harder to use props with . in them, cause you cannot use them as table slots as is, you need to use ["foo.bar"] =value  or "foo.bar":value and cannot use foo.bar = value
  "active":"active"
  "capzone.curTeamCapturingZone":"curTeamCapturingZone"
  "capzone.progress":"progress"
  "capzone.capTeam":"capTeam"
  "capzone.onlyTeamCanCapture":"only_team_cap"
  "ui_order":"ui_order"
  "capzone.alwaysShow":"alwaysShow"
  "capzone.title":"title"
  "capzone.caption":"caption"
  "capzone.icon":"icon"
  "capzone.owningTeam":"owningTeam"
  "capzone.ownTeamIcon":"ownTeamIcon"
  "capzone.isMultipleTeamsPresent":"isMultipleTeamsPresent"
  "capzone.presenceTeamCount": "presenceTeamCount"
}

local queryCapZones =  ::ecs.SqQuery("queryCapZones", {comps_ro = [["capzone.capTeam", ::ecs.TYPE_INT]]})

local function queryCapturedZones(hero_team) {
  local captured = 0
  local enemyCaptured = 0
  local total = 0
  queryCapZones.perform(function(eid, comp) {
    local zoneTeam = comp["capzone.capTeam"]
    if (zoneTeam != TEAM_UNASSIGNED) {
      if (zoneTeam == hero_team)
        ++captured
      else
        ++enemyCaptured
    }
    ++total
  })
  return {
    captured = captured
    enemyCaptured = enemyCaptured
    total = total
  }
}

local function getNarratorSound(name) {
  return localPlayerTeamInfo.value?[$"team.narrator_{name}"]
}

local function isHalfZonesCaptured(captured, total) {
  return total >= 2 && captured * 2 >= total && (captured - 1) * 2 < total
}

local function onZoneCaptured(evt, eid, comp) {
  if (evt[0] != eid)
    return
  local heroTeam = localPlayerTeam.value
  local capTeam = comp["capzone.capTeam"]
  local zones = queryCapturedZones(heroTeam)
  local zoneGroupName = ::ecs.get_comp_val(eid, "groupName", -1)
  local checkAllZonesInGroup = ::ecs.get_comp_val(eid, "capzone.checkAllZonesInGroup", false)

  if (checkAllZonesInGroup && allZonesInGroupCapturedByTeam(eid, capTeam, zoneGroupName)) {
    if (capTeam == heroTeam) {
      local last = getLastGroupToCaptureByTeam(eid, capTeam)
      if (last != null && last != zoneGroupName) {
        playMajorEvent({event="last_sector_left", text=::loc("One last sector left!"), myTeamScores=false, sound=getNarratorSound("oneSectorLeft")})
        return
      }
    }

    if (capTeam == heroTeam)
      playMajorEvent({event="sector_captured", text=::loc("We have captured sector!"), myTeamScores=false, sound=getNarratorSound("sectorCapturedAlly")})
    else
      playMajorEvent({event="sector_captured", text=::loc("Enemy has captured sector!"), myTeamScores=false, sound=getNarratorSound("sectorCapturedEnemy")})
    return
  }

  local e = null
  if (capTeam == heroTeam) {
    if (zones.captured == zones.total)
      e = {event="all_zones_captured", text=::loc("We have captured all zones!"), myTeamScores=true, sound=getNarratorSound("allPointsCapturedAlly")}
  } else {
    if (zones.captured == zones.total)
      e = {event="all_zones_captured", text=::loc("Enemy have captured all zones!"), myTeamScores=true, sound=getNarratorSound("allPointsCapturedEnemy")}
  }
  if (e?.sound != null && e.sound != "") {
    playMajorEvent(e)
    return
  }

  if (capTeam == heroTeam) {
    if (zones.captured + 1 == zones.total)
      e = {event="one_zone_to_capture", text=::loc("Most of all zones are captured, one left!"), myTeamScores=true, sound=getNarratorSound("onePointToCapture")}
    else if (isHalfZonesCaptured(zones.captured, zones.total))
      e = {event="half_zones_captured", text=::loc("We have captured half of all zones!"), myTeamScores=true, sound=getNarratorSound("halfPointsCaptured")}
    else
      e = {event="zone_captured", text=::loc("We have captured zone!"), myTeamScores=true, sound=getNarratorSound("pointCaptured")}
  } else {
    if (zones.captured == 1 && zones.enemyCaptured + 1 == zones.total)
      e = {event="one_zone_to_capture", text=::loc("Most of all zones are captured by enemy, only one left to defend!"), myTeamScores=false, sound=getNarratorSound("onePointToDefend")}
    else if (isHalfZonesCaptured(zones.enemyCaptured, zones.total))
      e = {event="half_zones_captured", text=::loc("Enemy have captured half of all zones!"), myTeamScores=false, sound=getNarratorSound("halfPointsCapturedEnemy")}
    else
      e = {event="zone_captured", text=::loc("Enemy have captured zone!"), myTeamScores=false, sound=getNarratorSound("pointCapturedEnemy")}
  }
  playMajorEvent(e)
}

local function notifyOnZoneVisitor(cur_team_capturing_zone, prev_team_capturing_zone, hero_team, only_team_cap) {
  //cur_team_capturing_zone: -1 - empty | -2 - more than one team | team_id
  if (prev_team_capturing_zone == cur_team_capturing_zone)
    return //no changes
  if (only_team_cap < 0)
    return // no events currently
  local isHeroAttacker = only_team_cap == hero_team
  local e = null
  if (isHeroAttacker) {
    if (cur_team_capturing_zone == hero_team)
      e = {event="zone_capture_start", text=::loc("We have started capturing zone."), myTeamScores=true, sound=getNarratorSound("pointCapturingAlly")}
    else if (cur_team_capturing_zone < 0)
      e = {event="zone_capture_stop", text=::loc("We have lost domination on zone and stopped capturing"), myTeamScores=false}
    else
      e = {event="zone_capture_enemy", text=::loc("Enemy is taking back control of target zone"), myTeamScores=false}
  } else {
    if (cur_team_capturing_zone == hero_team && prev_team_capturing_zone > 0)
      e = {event="zone_defend_start", text=::loc("Our troops are back on defence, fighting the enemy"), myTeamScores=true}
    else if (cur_team_capturing_zone > 0)
      e = {event="zone_defend_stop", text=::loc("Enemy troops are breaking through!"), myTeamScores=false, sound=getNarratorSound("pointCapturingEnemy")}
  }

  playMinorEvent(e)
}


local function onCapzonesInitialized(evt, eid, comp) {
  local zone = {
    eid = eid
//    zone_type= ::ecs.g_entity_mgr.getEntityTemplateName(eid)
    curTeamCapturingZone  = comp["capzone.curTeamCapturingZone"]
    prevTeamCapturingZone = comp["capzone.curTeamCapturingZone"]
    capTeam  = comp["capzone.capTeam"]
    progress = comp["capzone.progress"]
    active   = comp["active"]
    title    = comp["capzone.title"]
    icon     = comp["capzone.icon"]
    ui_order = comp["ui_order"] || 0
    caption  = comp["capzone.caption"]
    presenceTeamCount = comp["capzone.presenceTeamCount"].getAll()
    isCapturing = false
    only_team_cap = comp["capzone.checkAllZonesInGroup"] ?
                    comp["capzone.mustBeCapturedByTeam"] : comp["capzone.onlyTeamCanCapture"]
    heroInsideEid = INVALID_ENTITY_ID
    alwaysShow = comp["capzone.alwaysShow"]
    ownTeamIcon = comp["capzone.ownTeamIcon"].getAll()
    owningTeam = comp["capzone.owningTeam"]
    groupName = comp["groupName"]
    isMultipleTeamsPresent = comp["capzone.isMultipleTeamsPresent"]
  }
  zone.wasActive <- zone.active
  capZones[eid] <- zone
}


local function onHeroChanged(evt,eid, comp){
  local newHeroEid = evt[0]
  local zonesUpdate = {}
  foreach (zoneId, zone in capZones.value) {
    local prevHeroInside = zone["heroInsideEid"]
    local newHeroInside = is_entity_in_zone(newHeroEid, zoneId) ? newHeroEid : INVALID_ENTITY_ID
    if (newHeroInside != prevHeroInside)
      zonesUpdate[zoneId] <- zone.__merge({ heroInsideEid = newHeroInside })
  }
  if (zonesUpdate.len())
    capZones(@(v) v.__update(zonesUpdate))
}


local function onCapZoneChanged(evt, eid, comp) {
  local attrName = ::ecs.get_component_name_by_idx(evt[1])
  local attrVal = comp[attrName]
  local zone = capZones.value?[eid]

  if (zone==null)
    return

  local prop = attr2gui?[attrName]
  if (!prop)
    return

  local heroTeam = localPlayerTeam.value

  local cur_team_capturing_zone = (prop == "curTeamCapturingZone") ? attrVal : zone.curTeamCapturingZone
  local only_team_cap = (prop == "only_team_cap") ? attrVal : zone.only_team_cap

  if (prop == "curTeamCapturingZone" || (prop == "only_team_cap" && zone.only_team_cap >= 0)) {
    notifyOnZoneVisitor(cur_team_capturing_zone, zone.prevTeamCapturingZone, heroTeam, only_team_cap)
  }

  if (zone.only_team_cap < 0 && prop == "capTeam") {
    if (attrVal >= FIRST_GAME_TEAM && zone.capTeam < FIRST_GAME_TEAM) {
      local isHeroTeam = (attrVal==heroTeam)
      local isHero = isHeroTeam && is_entity_in_zone(controlledHeroEid.value, eid)
      local sound = getNarratorSound(isHero ? "pointCapturingPlayer" : isHeroTeam ? "pointCapturingAlly" : "pointCapturingEnemy")
      local e = {event="zone_capture_start", text=::loc("Zone is being captured"), myTeamScores=isHeroTeam, sound=sound}
      playerEvents.pushEvent(e)
    }
  }

  if (zone[prop] == attrVal)
    return

  local newZone = clone zone
  // It's not allowed to store a reference to ecs::Object or ecs::Array
  // So, call getAll() if it possible. getAll() == deepcopy.
  newZone[prop] = attrVal?.getAll != null ? attrVal.getAll() : attrVal
  newZone.isCapturing = newZone.curTeamCapturingZone != TEAM_UNASSIGNED
    && (newZone.progress != 1.0 || newZone.isMultipleTeamsPresent)
    && newZone.active

  if (prop == "curTeamCapturingZone")
    newZone.prevTeamCapturingZone = zone.curTeamCapturingZone
  if (prop == "active" && attrVal)
    newZone.wasActive = true

  capZones(@(v) v[eid] = newZone)
}


local function onCapzonesDestroy(evt, eid, comp) {
  if (eid in capZones.value)
    capZones(@(v) delete v[eid])
}


local function onZonePresenseChange(eid, visitor_eid, params={}) {
  local zone = capZones.value?[eid]
  if (!zone)
    return

  local hero_eid = controlledHeroEid.value
  if (visitor_eid == hero_eid)
    capZones(@(v) v[eid] = zone.__merge({ heroInsideEid = params?.leave ? INVALID_ENTITY_ID : hero_eid }))
}

local function onZoneEnter(evt, eid, comp){
  local visitor = evt[0]
  onZonePresenseChange(eid, visitor, {leave=false})
}

local function onZoneLeave(evt, eid, comp){
  local visitor = evt[0]
  onZonePresenseChange(eid, visitor, {leave=true})
}

::ecs.register_es("capzones_ui_state_es",
  {
    onChange = onCapZoneChanged,
    onInit = onCapzonesInitialized,
    onDestroy = onCapzonesDestroy,
    [EventCapZoneEnter] = onZoneEnter,
    [EventCapZoneLeave] = onZoneLeave,
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
    [EventHeroChanged] = onHeroChanged,
  },
  {
    comps_track = [
      ["capzone.progress", ::ecs.TYPE_FLOAT],
      ["active", ::ecs.TYPE_BOOL],
      ["capzone.owningTeam", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone.curTeamCapturingZone", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone.capTeam", ::ecs.TYPE_INT],
      ["capzone.alwaysShow", ::ecs.TYPE_BOOL, false],
      ["capzone.title", ::ecs.TYPE_STRING, ""],
      ["capzone.icon", ::ecs.TYPE_STRING, ""],
      ["capzone.caption", ::ecs.TYPE_STRING, ""],
      ["ui_order", ::ecs.TYPE_INT, 0],
      ["capzone.ownTeamIcon", ::ecs.TYPE_OBJECT],
      ["capzone.onlyTeamCanCapture", ::ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone.checkAllZonesInGroup", ::ecs.TYPE_BOOL, false],
      ["capzone.mustBeCapturedByTeam",::ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone.isMultipleTeamsPresent",::ecs.TYPE_BOOL, false],
      ["groupName",::ecs.TYPE_STRING, ""],
      ["capzone.presenceTeamCount", ::ecs.TYPE_OBJECT, {}]
    ],
  },
  { tags="gameClient" }
)


return {
  capZones = capZones
  activeCapZonesEids = activeCapZonesEids
  visibleZoneGroups = visibleZoneGroups
  whichTeamAttack = whichTeamAttack
}
 