local {TEAM_UNASSIGNED} = require("team")
local is_teams_friendly = require("globals/is_teams_friendly.nut")
local {EventPlayerPossessedEntityDied} = require("deathevents")

local function modifyAfkTime(eid, change) {
  local afkTime = ::ecs.get_comp_val(eid, "player_activity.afkTime", 0.0)
  afkTime = ::max(0, afkTime + change)
  ::ecs.set_comp_val(eid, "player_activity.afkTime", afkTime)
}

local findActiveZone = ::ecs.SqQuery("findActiveZone", {comps_ro = [ ["active", ::ecs.TYPE_BOOL]], comps_rq=["capzone"]},"active")
local function capzoneActivity(eid) {
  local peid = ::ecs.get_comp_val(eid, "possessed", INVALID_ENTITY_ID)
  local team = ::ecs.get_comp_val(eid, "team")
  local tm = ::ecs.get_comp_val(peid, "transform")

  local pos = tm.getcol(3)
  local minDistance = -1
  local isCapturedByTeam = false
  local isCapturedByPlayer = false

  local zones = []
  findActiveZone.perform(function(eid, comp) {
      zones.append(eid)
    })

  foreach (zoneEid in zones) {
    local zoneTm = ::ecs.get_comp_val(zoneEid, "transform")
    if (!zoneTm)
      continue
    local zonePos = zoneTm.getcol(3)
    local teamCapturingZone =
      ::ecs.get_comp_val(zoneEid, "capzone.curTeamCapturingZone", TEAM_UNASSIGNED)
    local zoneRadius = ::ecs.get_comp_val(zoneEid, "sphere_zone.radius", 0)
    local distance = ::max(0, (pos - zonePos).length() - zoneRadius)

    if (teamCapturingZone == team)
      isCapturedByTeam = true
    if (distance == 0)
      isCapturedByPlayer = true
    if (minDistance == -1 || distance < minDistance)
      minDistance = distance
  }

  local mults = {
    maxZoneDistance          = 50.0
    zoneDistanceMult         = 0.5
    capturedZoneDistanceMult = 2.0
    zonePlayerCaptureMult    = 3.5
  }
  foreach (name, defValue in mults)
    mults[name] = ::ecs.get_comp_val(peid, $"player_activity.{name}", defValue)


  local activity = 0.0
  if (minDistance != -1) {
    local mult = mults.zoneDistanceMult + (isCapturedByTeam ? mults.capturedZoneDistanceMult : 0)
    activity += mult * ::clamp(1.0 - (minDistance / mults.maxZoneDistance), 0.0, 1.0)
  }
  if (minDistance == 0)
    activity += mults.zonePlayerCaptureMult

  return activity
}


local function onUpdate(dt, eid, comp){
  local peid = ::ecs.get_comp_val(eid, "possessed", INVALID_ENTITY_ID)
  if (peid == INVALID_ENTITY_ID)
    return

  local isEnabled = ::ecs.get_comp_val(peid, "player_activity.enabled", false)
  if (!isEnabled)
    return

  local afkMultiplier = 0.0
  afkMultiplier += 1
  afkMultiplier -= capzoneActivity(eid)

  modifyAfkTime(eid, dt * afkMultiplier)
}

local function onPlayerEntityDied(evt, eid, comp) {
  local victimEid = evt[0]
  local killerEid = evt[1]

  if (::ecs.get_comp_val(victimEid, "player_activity.enabled", false))
    modifyAfkTime(eid, -::ecs.get_comp_val(victimEid, "player_activity.deathActivity", 3.0))

  if (::ecs.get_comp_val(killerEid, "player_activity.enabled", false)) {
    local isOpponent = !is_teams_friendly(::ecs.get_comp_val(killerEid, "team", TEAM_UNASSIGNED), ::ecs.get_comp_val(victimEid, "team", TEAM_UNASSIGNED))
    if (isOpponent)
      modifyAfkTime(eid, -::ecs.get_comp_val(killerEid, "player_activity.killActivity", 8.0))
  }
}

local comps = {
  comps_rw = [ ["player_activity.afkTime", ::ecs.TYPE_FLOAT] ],
  comps_ro = [ ["team", ::ecs.TYPE_INT] ]
}

::ecs.register_es("player_activity",
  {
    onUpdate = onUpdate,
    [EventPlayerPossessedEntityDied] = onPlayerEntityDied
  },
  comps,
  { updateInterval=1.0, tags="server", after="*", before="*" }
)
 