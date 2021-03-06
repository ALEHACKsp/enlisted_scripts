local rndInstance = require("std/rand.nut")()
local {FLT_MAX} = require("math")

local groupRespawnGroupsQuery = ::ecs.SqQuery("groupRespawnGroupsQuery", {comps_ro=["selectedGroup", "transform", "respawnIconType", "team"], comps_rq=["autoRespawnSelector"]})
local capzoneQuery = ::ecs.SqQuery("capzoneQuery", {comps_ro=["active", "transform", "capzone.capTeam"], comps_rq=["capzone"]})
local forceRespawnGroupsQuery = ::ecs.SqQuery("forceRespawnGroupsQuery", {comps_ro=["respawnBaseGroup", "team", "active", "respawnbaseType"], comps_rq=["forceRepawnBasePriority"]})

const MIN_NUM_OF_POINTS = 2 // minimum number of points from which select random spawn

local function getRandomRespawnGroup(respawns) {
  local respawnsArray = respawns.topairs()
  if (respawnsArray.len() == 0)
    return -1
  local randId = rndInstance.rint(0, respawnsArray.len() - 1)
  local randElem = respawnsArray[randId]
  return randElem?[0] ?? -1
}

local function findNearestPoint(target, points) {
  local minDistance = FLT_MAX
  local nearestKey = null
  foreach (key, point in points) {
    local distance = (target - point).lengthSq()
    if (distance < minDistance) {
      minDistance = distance
      nearestKey = key
    }
  }
  return [nearestKey, minDistance]
}

local function findNearestRespawnGroups(respawnGroups, capZonesPositions) {
  local respawnGroupsMap = {}
  foreach (zonePos in capZonesPositions) {
    local resultGroup = findNearestPoint(zonePos, respawnGroups)[0] ?? -1
    if (respawnGroupsMap?[resultGroup] == null)
      respawnGroupsMap[resultGroup] <- resultGroup
  }
  return respawnGroupsMap
}

local function sortRespawnGroupsByDistance(respawnGroups, capZonesPositions) {
  local respawnGroupsDistance = []
  foreach (respawnGroup, respawnPos in respawnGroups){
    local minDistance = findNearestPoint(respawnPos, capZonesPositions)[1]
    respawnGroupsDistance.append({group = respawnGroup, distance = minDistance})
  }
  respawnGroupsDistance.sort(@(a, b) a.distance <=> b.distance)
  return respawnGroupsDistance
}

local function getRespawnGroups(canUseRespawnbaseType, forTeam) {
  local respawnGroups = {}
  groupRespawnGroupsQuery(function(eid, comps) {
    if (comps.respawnIconType == canUseRespawnbaseType && comps.team == forTeam)
      respawnGroups[comps.selectedGroup] <- comps.transform[3]
  })
  return respawnGroups
}

local function getCapzonePositions(team) {
  local capzonesPos = []
  capzoneQuery.perform(function(eid, comps) {
    if (comps.active && comps["capzone.capTeam"] != team)
      capzonesPos.append(comps.transform[3])
  })
  return capzonesPos
}

local function findForceRespawnBaseGroup(team, respawnType) {
  local respawnGroup = -1
  forceRespawnGroupsQuery.perform(function(eid, comps) {
    if (comps.active && comps.team == team && respawnType == comps.respawnbaseType)
      respawnGroup = comps.respawnBaseGroup
  })
  return respawnGroup
}

local function getAdditionalForSpawnTab(spawnTab, respawnGroups, capZonesPositions){
  local additionalTab = {}
  local allSpawnsByDistance = sortRespawnGroupsByDistance(respawnGroups, capZonesPositions)
  local needAddCount = MIN_NUM_OF_POINTS - spawnTab.len()
  for (local i = 0; i < allSpawnsByDistance.len() && needAddCount!=0; i++)
    if (spawnTab?[allSpawnsByDistance[i].group] == null) {
      additionalTab[allSpawnsByDistance[i].group] <- allSpawnsByDistance[i].group
      needAddCount--
    }
  return additionalTab
}

local function getRespawnGroup(canUseRespawnbaseType, team) {
  local forceRespawnGroup = findForceRespawnBaseGroup(team, canUseRespawnbaseType)
  if (forceRespawnGroup >= 0)
    return forceRespawnGroup
  local respawnGroups = getRespawnGroups(canUseRespawnbaseType, team)
  local capZonesPositions = getCapzonePositions(team)
  local hasEnoughSpawnGroups = respawnGroups.len() >= MIN_NUM_OF_POINTS
  local noAvailableZones = capZonesPositions.len() == 0
  if (noAvailableZones || !hasEnoughSpawnGroups)
    return getRandomRespawnGroup(respawnGroups)

  local prioritySpawnList = findNearestRespawnGroups(respawnGroups, capZonesPositions)
  hasEnoughSpawnGroups = prioritySpawnList.len() >= MIN_NUM_OF_POINTS
  if (!hasEnoughSpawnGroups)
    prioritySpawnList.__update(getAdditionalForSpawnTab(prioritySpawnList, respawnGroups, capZonesPositions))
  return getRandomRespawnGroup(prioritySpawnList)
}

return getRespawnGroup 