local {mkCountdownTimerPerSec} = require("ui/helpers/timers.nut")
local {localPlayerEid} = require("ui/hud/state/local_player.nut")

local respEndTime = persist("respEndTime", @() Watched(-1))
local canRespawnTime = persist("canRespawnTime", @() Watched(-1))
local isInSpawn = persist("isInSpawn", @() Watched(false))
local respEndTotalTime = ::Computed(@() (respEndTime.value > 0) ? respEndTime.value : -1)
local respawnerEid = persist("respawnerEid", @() Watched(INVALID_ENTITY_ID))
local state = {
  respEndTime = respEndTime
  canRespawnTime = canRespawnTime
  isInSpawn = isInSpawn
  respawnerEid = respawnerEid
  needSpawnMenu = ::Computed(@() isInSpawn.value || respEndTime.value > 0 || canRespawnTime.value > 0)
  respEndTotalTime = respEndTotalTime
  timeToRespawn = mkCountdownTimerPerSec(respEndTotalTime)
}

::ecs.register_es("respawns_simple_state_ui_es", {
    [["onInit","onChange"]] = function(evt, eid, comp){
      local playerEid = comp["respawner.player"]
      if (playerEid != INVALID_ENTITY_ID && playerEid != localPlayerEid.value)
        return

      respawnerEid(eid)
      if (eid != INVALID_ENTITY_ID) {
        isInSpawn(comp["in_spawn"])
        canRespawnTime(comp["respawner.canRespawnTime"])
        respEndTime(comp["respawner.respEndTime"])
      }
      else{
        isInSpawn(false)
        canRespawnTime(-1)
        canRespawnTime(-1)
      }
    },
    [["onDestroy"]] = function(evt, eid, comp){
      local playerEid = comp["respawner.player"]
      if (playerEid != INVALID_ENTITY_ID && playerEid != localPlayerEid.value)
        return

      respawnerEid(INVALID_ENTITY_ID)
      isInSpawn(false)
      canRespawnTime(-1)
      respEndTime(-1)
    },
  },
  {
    comps_track = [
      ["respawner.player", ::ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["respawner.respEndTime", ::ecs.TYPE_FLOAT, -1.0],
      ["respawner.canRespawnTime", ::ecs.TYPE_FLOAT, -1.0],
      ["in_spawn", ::ecs.TYPE_BOOL, false],
    ]
    comps_rq = [["input.enabled", ::ecs.TYPE_BOOL]]
  }
)

return state 