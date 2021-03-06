local {curTime} = require("ui/hud/state/time_state.nut")
local {frameUpdateCounter} = require("ui/scene_update.nut")
local {lerp} = require("std/math.nut")

local entityToUse = Watched(INVALID_ENTITY_ID)
local entityUseStart = Watched(-1)
local entityUseEnd = Watched(-1)
::ecs.register_es("medkitUsage",{
  [["onInit","onChange"]] = function(eid,comp){
    entityUseStart(comp["human_inventory.entityUseStart"])
    entityUseEnd(comp["human_inventory.entityUseEnd"])
    entityToUse(comp["human_inventory.entityToUse"])
  },
  onDestroy = @(eid,comp) entityUseEnd(-1.0) ?? entityUseStart(-1.0) ?? entityToUse(INVALID_ENTITY_ID)
}, {comps_track=[
    ["human_inventory.entityUseStart",::ecs.TYPE_FLOAT],
    ["human_inventory.entityUseEnd",::ecs.TYPE_FLOAT],
    ["human_inventory.entityToUse",::ecs.TYPE_EID]
  ], comps_rq=["watchedByPlr"]})

local itemUseProgress = Watched(0)

local function calcitemUseProgress(...){
  local res = 0
  if (curTime.value <= entityUseEnd.value)
    res = lerp(entityUseStart.value, entityUseEnd.value, 0.0, 100.0, curTime.value)
  itemUseProgress(res)
}

entityUseEnd.subscribe(calcitemUseProgress)
entityUseStart.subscribe(calcitemUseProgress)
frameUpdateCounter.subscribe(calcitemUseProgress)

return {
  medkitStartTime = entityUseStart
  medkitEndTime = entityUseEnd
  entityToUse
  entityUseEnd
  entityUseStart
  itemUseProgress
}
 