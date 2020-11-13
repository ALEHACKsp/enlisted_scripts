  

                                                      
                                               
                                      
  


local respawnStateBase = require("hero_respawn.nut")
local vehiclesData = require("enlisted/ui/hud/state/vehiclesData.nut")
local frp = require("std/frp.nut")
local { isEqual } = require("std/underscore.nut")
local app = require("net")
local {mkCountdownTimerPerSec} = require("ui/helpers/timers.nut")
local log = require("std/log.nut")().with_prefix("[HERO_RESPAWN]")
local { localPlayerTeamInfo } = require("enlisted/ui/hud/state/teams.nut")
local { localPlayerEid } = require("ui/hud/state/local_player.nut")
local { warningShow, addWarnings, WARNING_PRIORITIES } = require("ui/hud/state/warnings.nut")
local armyData = require("armyData.nut")
local soldiersData = require("soldiersData.nut")
local vehicleRespawnBases = require("enlisted/ui/hud/state/vehicleRespawnBases.nut")
local { get_can_use_respawnbase_type } = require("game/utils/respawn_base.nut")
local armiesPresentation = require("enlisted/globals/armiesPresentation.nut")
local squadsPresentation = require("enlisted/globals/squadsPresentation.nut")

local state = respawnStateBase
local { isInSpawn, respEndTime, canRespawnTime } = state
local canChangeRespawnParams = ::Computed(@() respEndTime.value > 0 || canRespawnTime.value > 0)

local spawnCount = persist("spawnCount", @() Watched(0))
local respawnPenaltyTotalTime = persist("respawnPenaltyTotalTime", @() Watched(0.0))
local respawnsInBot = persist("respawnsInBot", @() Watched(false))
local respawnLastActiveTime = persist("respawnLastActiveTime", @() Watched(-1))
local respawnInactiveTimeout = persist("respawnInactiveTimeout", @() Watched(-1))
local curSoldierIdx = persist("curSoldierIdx", @() Watched(0))
local squadIndexForSpawn = Watched(-1)
const noRespawnsLeftWarningId = "noRespawnsLeft"

local vehicleInfo = ::Computed(function() {
  local squad = armyData.value?.squads[squadIndexForSpawn.value]
  return vehiclesData.value?[squad?.curVehicle.guid]
})

local canUseRespawnbaseByType = ::Computed(@() get_can_use_respawnbase_type(vehicleInfo.value?.gametemplate) ?? "human")

addWarnings({  //noRespawnsLeft hint is on the red bg, so it better to be white color
  [noRespawnsLeftWarningId]         = { priority = WARNING_PRIORITIES.ULTRALOW, timeToShow = 30, color = Color(255, 255, 255, 200) }
})
state = state.__merge(
  {
    respawnsInBot = respawnsInBot
    respawnInactiveTimeout = respawnInactiveTimeout
    respawnLastActiveTime = respawnLastActiveTime
    canChangeRespawnParams = canChangeRespawnParams
    canUseRespawnbaseByType = canUseRespawnbaseByType
    squadIndexForSpawn = squadIndexForSpawn
    vehicleInfo = vehicleInfo
    respawnPenaltyTotalTime = respawnPenaltyTotalTime
  },
  make_persists(persist, {
    //params updated by es
    respawnInactiveShowTimer = Watched(-1)
    isSpectatorEnabled = Watched(false)

    vehicleRespawnsBySquad = Watched([])

    //control - can be changed by server or by ui
    respRequested = Watched(false)

    //other params

    spawnSquadId = Watched(null)
    squadMemberIdForSpawn = Watched(0)
    squadsRevivePoints = Watched([])
    soldierRevivePoints = Watched([])
    spawnCount = Watched(0)

    isFirstSpawn = Watched(false)
    respawnGroupId = Watched(-1)
    vehicleSquadSelected = Watched(false)
  })
)

state.respawnGroupId.subscribe(@(v) state.respRequested(false))

local vehicleRespawnsBySquad = state.vehicleRespawnsBySquad

local isSpawnAllowedByCount = ::Computed(function(){
  if (respawnsInBot.value)
    return true
  local total = localPlayerTeamInfo.value?["team.eachSquadMaxSpawns"] ?? 0
  return total <= 0 || total > spawnCount.value
})
state.isSpawnAllowedByCount <- isSpawnAllowedByCount
state.needSpawnMenu <- ::Computed(@()
  isSpawnAllowedByCount.value && (isInSpawn.value || canChangeRespawnParams.value)
)

local timeToCanRespawn = mkCountdownTimerPerSec(state.canRespawnTime)
state.timeToCanRespawn <- timeToCanRespawn

local isSquadAvailableByTime = Watched([])
local spawnVehicleEndTimesBySquad = ::Computed(@() vehicleRespawnsBySquad.value.map(@(v) v.respInVehicleEndTime))
local canSpawnOnVehicleBySquad = ::Computed(@() vehicleRespawnsBySquad.value.map(@(v, k) v.maxSpawnVehiclesOnPoint == -1 && (isSquadAvailableByTime.value?[k] ?? true)))
state.canSpawnOnVehicleBySquad <- canSpawnOnVehicleBySquad


local function updateVehicleSpawnAvailableTimer(...) {
  local curTime = app.get_sync_time()
  isSquadAvailableByTime(spawnVehicleEndTimesBySquad.value.map(@(v) v <= curTime))
  local nextEndTime = spawnVehicleEndTimesBySquad.value
    .filter(@(it) it > curTime)
    .reduce(@(a,b) min(a,b)) ?? -1.0
  local minDelay = nextEndTime - curTime
  if (minDelay > 0) {
    ::gui_scene.clearTimer(updateVehicleSpawnAvailableTimer)
    ::gui_scene.setTimeout(minDelay, updateVehicleSpawnAvailableTimer)
  }
}
spawnVehicleEndTimesBySquad.subscribe(updateVehicleSpawnAvailableTimer)
updateVehicleSpawnAvailableTimer()

local function requestRespawn() {
  local squadId = squadIndexForSpawn.value
  local spawnGroup = state.respawnGroupId.value
  local memberId = state.squadMemberIdForSpawn.value
  log($"Request respawn, respawnerEid {state.respawnerEid.value}, squadId {squadId}, memberId {memberId}")
  ::ecs.client_request_unicast_net_sqevent(state.respawnerEid.value, ::ecs.event.CmdRequestRespawn({ squadId = squadId, memberId = memberId, spawnGroup = spawnGroup}))
}

local function cancelRequestRespawn() {
  local squadId = squadIndexForSpawn.value
  local memberId = state.squadMemberIdForSpawn.value
  log($"Request cancel respawn, respawnerEid {state.respawnerEid.value}, squadId {squadId}, memberId {memberId}")
  ::ecs.client_request_unicast_net_sqevent(state.respawnerEid.value, ::ecs.event.CmdCancelRequestRespawn({ squadId = squadId, memberId = memberId }))
}

local { spawnSquadId, squadMemberIdForSpawn, respRequested, squadsRevivePoints, soldierRevivePoints } = state

local hasVehicleRespawns = ::Computed(@() vehicleRespawnBases.value.eids.len() > 0)
local squadsList = ::Computed(function() {
  local armyId = armyData.value?.armyId
  return (armyData.value?.squads ?? [])
    .map(function(squad, idx) {
      local squadId = squad.squadId
      local res = {
        squadId = squadId
        icon = squadsPresentation?[armyId]?[squadId].icon
      }
      if ((squad?.battleExpBonus ?? 0) > 0)
        res.premIcon <- armiesPresentation?[armyId].premIcon
      local readinessPercent = squadsRevivePoints.value?[idx] ?? -1
      local canSpawn = readinessPercent == 100
      if (canSpawn && squad.curVehicle != null) {
        local canUseRespawnbaseType = get_can_use_respawnbase_type(squad.curVehicle?.gametemplate)
        local respawnbasesCount = vehicleRespawnBases.value.byType?[canUseRespawnbaseType].len() ?? 0
        local canSpawnOnVehicle = canSpawnOnVehicleBySquad.value?[idx] ?? false
        canSpawn = hasVehicleRespawns.value && respawnbasesCount > 0 && canSpawnOnVehicle && readinessPercent == 100
      }

      return res.__update({
        name = squad?.locId ? ::loc(squad.locId) : "---"
        squadType = squad?.squadType ?? "unknown"
        level = squad?.level ?? 0
        squadSize = squad.squad.len()
        vehicle = squad.curVehicle
        vehicleType = squad?.vehicleType
        isFaded = !canSpawn

        canSpawn = canSpawn
        readinessPercent = readinessPercent
      })
    })
  }
)

local function onActive() {
  respawnLastActiveTime(app.get_sync_time())
  respRequested(false)
}

armyData.subscribe(@(data) spawnSquadId(data?.curSquaId))
spawnSquadId.subscribe(function(squadId) {
  onActive()
  squadIndexForSpawn(squadsList.value.findindex(@(s) s.squadId == squadId) ?? 0)
})
curSoldierIdx.subscribe(function(i){
  onActive()
  squadMemberIdForSpawn(i)
})

local function updateSpawnSquadId() {
  local squads = squadsList.value
  local bestSquadForSpawn = squads?[0]
  local maxReadinessPercent = 0
  foreach(squad in squads)
    if (squad.canSpawn && squad.readinessPercent > maxReadinessPercent) {
      bestSquadForSpawn = squad
      maxReadinessPercent = squad.readinessPercent
    }
  spawnSquadId(bestSquadForSpawn?.squadId)
}

local curSquadData = ::Computed(@()
  squadsList.value.findvalue(@(val) val?.squadId == spawnSquadId.value))

local soldiersList = ::Computed(function() {
  local squadId = spawnSquadId.value
  local squads = armyData.value?.squads ?? []
  local squadIndx = squads.findindex(@(s) s.squadId == squadId)
  local squad = squads?[squadIndx]

  local readinessPercents = soldierRevivePoints.value?[squadIndx] ?? []

  return (squad?.squad ?? [])
    .map(@(s) soldiersData.value?[s.guid]?.__update({
      canSpawn = (readinessPercents?[s.id] ?? 100) == 100
    }))
    .filter(@(s) s != null)
})

local canSpawnCurrentSoldier = ::Computed(@() soldiersList.value?[curSoldierIdx.value]?.canSpawn ?? true)
local canSpawnCurrent = ::Computed(@() (curSquadData.value?.canSpawn ?? false) && canSpawnCurrentSoldier.value)

local findReadySoldier = @(squadIndex) soldierRevivePoints.value?[squadIndex]?.findindex(@(readinessPercent) readinessPercent == 100)

soldiersList.subscribe(function(_) {
  curSoldierIdx(squadIndexForSpawn.value < 0 ? 0 : findReadySoldier(squadIndexForSpawn.value) ?? 0)
})

state = state.__merge(
  {
    squadsList = squadsList
    curSquadData = curSquadData
    canSpawnCurrent = canSpawnCurrent
    canSpawnCurrentSoldier = canSpawnCurrentSoldier
    soldiersList = soldiersList
    curSoldierIdx = curSoldierIdx
    onActive = onActive
    updateSpawnSquadId = updateSpawnSquadId
  }
)

local isSuicidePenalty = ::Computed(@() respawnPenaltyTotalTime.value > 0.0 && timeToCanRespawn.value > 0)
local respawnPenaltyTime = ::Computed(@() isSuicidePenalty.value ? respawnPenaltyTotalTime.value : 0.0)
state.respawnPenaltyTime <- respawnPenaltyTime

local respEndTotalTime = ::Computed(function(){
  if (!canSpawnCurrent.value)
    return -1
  if (respEndTime.value > 0)
    return respEndTime.value + respawnPenaltyTime.value
  if (respawnLastActiveTime.value > 0 )
    return respawnLastActiveTime.value + respawnInactiveTimeout.value + respawnPenaltyTime.value
  return -1
})

state.timeToRespawn <- mkCountdownTimerPerSec(respEndTotalTime)

//This is espically ugly code
local isChangedByUi = true
state.respRequested.subscribe(function(v) {
  if (isChangedByUi) {
    if (v)
      requestRespawn()
    else
      cancelRequestRespawn()
  }
})

state.needSpawnMenu.subscribe(function(need) { if (need) state.respawnLastActiveTime(app.get_sync_time()) })
local pendingResp = null
frp.subscribe([state.needSpawnMenu, respEndTime, respEndTotalTime, state.timeToRespawn],
  function(v) {
    if (pendingResp)
      return
    //wait for all watches update their values before send respawn event
    pendingResp = function() {
      pendingResp = null
      log("Check pending resp. respEndTime = {0}, respEndTotalTime = {1}, timeToRespawn = {2} "
        .subst(state.respEndTime.value, respEndTotalTime.value, state.timeToRespawn.value))
      if (state.needSpawnMenu.value && respEndTime.value <= 0 && respEndTotalTime.value > 0
          && state.timeToRespawn.value == 0)
        requestRespawn()
    }
    ::gui_scene.setTimeout(0.1, pendingResp)
  })

local wasNoRespLeftShown = false
local pendingCheckWarning = null
frp.subscribe([state.isSpawnAllowedByCount, canChangeRespawnParams, respawnsInBot, state.isSpectatorEnabled],
  function(_) {
    if (wasNoRespLeftShown || pendingCheckWarning || state.isSpawnAllowedByCount.value)
      return
    pendingCheckWarning = function() { //wait until state full update
      pendingCheckWarning = null
      if (!state.isSpectatorEnabled.value && (respawnsInBot.value || !canChangeRespawnParams.value))
        return
      warningShow(noRespawnsLeftWarningId)
      wasNoRespLeftShown = true
    }
    ::gui_scene.setTimeout(0.1, pendingCheckWarning)
  })


local debugSpawn = persist("debugSpawn", @() Watched(null))
local beforeDebugSpawn = persist("beforeDebugSpawn", @() Watched(null))
local function setDebugMode(isRespawnInBot) {
  local isChanged = debugSpawn.value?.respawnsInBot != isRespawnInBot
  if (!isChanged) {
    foreach(key, value in beforeDebugSpawn.value)
      state[key](value)
    beforeDebugSpawn(null)
    debugSpawn(null)
    return
  }
  local newData = {
    respawnsInBot = isRespawnInBot
    respEndTime = 300 + app.get_sync_time()
    canRespawnTime = 35 + app.get_sync_time()
  }
  debugSpawn(newData)
  if (!beforeDebugSpawn.value)
    beforeDebugSpawn(newData.map(@(value, key) state[key].value))
  foreach(key, value in newData)
    state[key](value)
}

console.register_command(@() setDebugMode(false), "respawn.debugSquad")
console.register_command(@() setDebugMode(true), "respawn.debugMember")

local function equalUpdate(watch, newVal) {
  if (!isEqual(watch.value, newVal))
    watch(newVal)
}

local function trackComponents(evt, eid, comp) {
  local playerEid = comp["respawner.player"]
  if (playerEid != INVALID_ENTITY_ID && playerEid != localPlayerEid.value)
    return

  if (eid != INVALID_ENTITY_ID) {
    state.respawnsInBot(comp["respawner.respToBot"])
    state.respawnInactiveTimeout(comp["respawner.respawnWhenInactiveTimeout"])
    state.respawnInactiveShowTimer(comp["respawner.respawnWhenInactiveShowTimer"])
    state.isFirstSpawn(comp["respawner.isFirstSpawn"])
    state.isSpectatorEnabled(comp["respawner.spectatorEnabled"])
    equalUpdate(vehicleRespawnsBySquad, comp["respawner.vehicleRespawnsBySquad"].getAll())
    isChangedByUi = false
    log("Received from server respawner.respRequested = {0}, respawner.respEndTime = {1}, respawner.canRespawnTime = {2}"
      .subst(comp["respawner.respRequested"], comp["respawner.respEndTime"], comp["respawner.canRespawnTime"]))
    state.respRequested(comp["respawner.respRequested"])
    isChangedByUi  = true
  } else {
    state.respawnsInBot(false)
    state.isFirstSpawn(false)
    equalUpdate(vehicleRespawnsBySquad, {})
  }
}

::ecs.register_es("respawns_state_ui_es", {
    [["onInit","onDestroy",::ecs.EventComponentChanged,::ecs.EventScriptReloaded]] = trackComponents,
  },
  {
    comps_track = [
      ["respawner.respToBot", ::ecs.TYPE_BOOL],
      ["respawner.respEndTime", ::ecs.TYPE_FLOAT, -1.0],
      ["respawner.canRespawnTime", ::ecs.TYPE_FLOAT, -1.0],
      ["respawner.respawnWhenInactiveTimeout", ::ecs.TYPE_FLOAT, -1.0],
      ["respawner.respawnWhenInactiveShowTimer", ::ecs.TYPE_FLOAT, -1.0],
      ["respawner.respRequested", ::ecs.TYPE_BOOL, false],
      ["respawner.player", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["respawner.isFirstSpawn", ::ecs.TYPE_BOOL, false],
      ["in_spawn", ::ecs.TYPE_BOOL, false],
      ["respawner.vehicleRespawnsBySquad", ::ecs.TYPE_ARRAY],
      ["respawner.spectatorEnabled", ::ecs.TYPE_BOOL, false],
    ]
    comps_rq = [["input.enabled", ::ecs.TYPE_BOOL]]
  }
)

local function trackSquadComponents(evt, eid, comp) {
  if (eid != localPlayerEid.value)
    return
  equalUpdate(squadsRevivePoints, comp["squads.revivePointsList"]?.getAll() ?? [])
  state.spawnCount(comp["squads.spawnCount"])
  state.respawnPenaltyTotalTime(comp["squads.respawnPenaltyTime"])
}

::ecs.register_es("squads_state_ui_es", {
    [["onInit","onDestroy","onChange"]] = trackSquadComponents,
}, {
  comps_track = [
    ["squads.revivePointsList", ::ecs.TYPE_ARRAY],
    ["squads.spawnCount", ::ecs.TYPE_INT],
    ["squads.respawnPenaltyTime", ::ecs.TYPE_FLOAT],
  ]
})

::ecs.register_es("solder_revive_points_state_ui_es", {
    [["onInit","onDestroy","onChange"]] = function(evt, eid, comp) {
      if (eid == localPlayerEid.value)
        equalUpdate(soldierRevivePoints, comp["soldier_revive_points.points"]?.getAll() ?? [])
    }
}, {
  comps_track = [["soldier_revive_points.points", ::ecs.TYPE_ARRAY]]
})


::ecs.register_es("squads_state_show_respawn_ui_es",
  {[::ecs.sqEvents.EventOnSpawnError] = @ (evt, eid, comp) log($"Spawn Error: {evt.data.reason}")},
  {comps_rq = ["player"]})

return state
 