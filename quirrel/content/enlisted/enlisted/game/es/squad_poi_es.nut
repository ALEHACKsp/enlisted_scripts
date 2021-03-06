local {EventZoneIsAboutToBeCaptured, EventZoneCaptured} = require("zoneevents")
local {EventLevelLoaded} = require("gameevents")
local pathfinder = require("pathfinder")

local teamsQuery = ::ecs.SqQuery("teamsQuery", {comps_ro=["team.id"]})
local activeCapzonesQuery = ::ecs.SqQuery("activeCapzonesQuery", {comps_ro=["transform", ["active", ::ecs.TYPE_BOOL], ["sphere_zone.radius", ::ecs.TYPE_FLOAT, 0.0]], comps_rq=["capzone"]}, "active")
local activeRespawnBasesQuery = ::ecs.SqQuery("activeRespawnBasesQuery", {comps_ro=["transform", "team", ["active", ::ecs.TYPE_BOOL]], comps_rq=["respbase"]}, "active")

local function findPath(from, to, rad) {
  return pathfinder.find_path(
    pathfinder.project_to_nearest_navmesh_point(from, rad),
    pathfinder.project_to_nearest_navmesh_point(to, 0.5),
    rad, 1.0, 0.25)
}

local function findPointOnPath(path, t) {
  if (!path || (path?.len() ?? 0) <= 0)
    return null

  local pathLength = 0.0;
  for (local i = 0; i < path.len() - 1; ++i)
    pathLength += (path[i + 1] - path[i]).length()

  local targetPathLength = t * pathLength;
  for (local i = 0; i < path.len() - 1; ++i) {
    local len = (path[i + 1] - path[i]).length()
    local d = targetPathLength - len
    if (d > 0.0) {
      targetPathLength -= len
      continue
    }
    return path[i] + (path[i + 1] - path[i]) * (targetPathLength / len)
  }

  return null
}

local function updateSquadPOI(evt, eid, comp) {
  local activeCapzones = []
  activeCapzonesQuery.perform(function (eid, comp){
        activeCapzones.append([comp.transform.getcol(3), comp["sphere_zone.radius"] > 0.0 ? comp["sphere_zone.radius"] : comp.transform.getcol(0).length() ])
      })

  teamsQuery.perform(function (eid, teamComp) {
    local enemyRespawnBases = []
    activeRespawnBasesQuery.perform(function (eid, respawnBaseComp) {
      if (respawnBaseComp.team != teamComp["team.id"])
        enemyRespawnBases.append(respawnBaseComp.transform.getcol(3))
    })

    local points = []
    foreach (respawnBase in enemyRespawnBases)
      foreach (capzone in activeCapzones) {
        local pointOnPath = findPointOnPath(findPath(capzone[0], respawnBase, capzone[1]), 0.35)
        if (pointOnPath) {
          points.append(pointOnPath)
        }
      }
    comp.pointsOfInterest[teamComp["team.id"].tostring()] = points
  })
}

::ecs.register_es("squad_poi_capzone_es", {
  [::ecs.EventEntityCreated] = @(evt, eid, comp) ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.CmdUpdateSquadPOI()),
  [::ecs.sqEvents.EventEntityActivate] = @(evt, eid, comp) ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.CmdUpdateSquadPOI()),
}, { comps_rq = ["capzone"] }, {tags="server"})

::ecs.register_es("squad_poi_respbase_es", {
  [::ecs.EventEntityCreated] = @(evt, eid, comp) ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.CmdUpdateSquadPOI()),
  [::ecs.sqEvents.EventEntityActivate] = @(evt, eid, comp) ::ecs.g_entity_mgr.broadcastEvent(::ecs.event.CmdUpdateSquadPOI()),
}, { comps_rq = ["respbase"] }, {tags="server"})

::ecs.register_es("squad_poi_es", {
  [::ecs.EventEntityCreated] = updateSquadPOI,
  [::ecs.sqEvents.CmdUpdateSquadPOI] = updateSquadPOI,
  [EventZoneCaptured] = updateSquadPOI,
  [EventZoneIsAboutToBeCaptured] = updateSquadPOI,
  [EventLevelLoaded] = updateSquadPOI,
},
{ comps_rw = [["pointsOfInterest", ::ecs.TYPE_OBJECT]] },
{tags="server"})
 