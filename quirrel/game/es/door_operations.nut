local {Point3} = require("dagor.math")
local {get_sync_time} = require("net")
local {CmdUse} = require("gameevents")

local doorComps ={
  comps_rw = [
    ["door_operations.reqState", ::ecs.TYPE_BOOL],
    ["door_operations.curState", ::ecs.TYPE_BOOL],
    ["rendinst_axis_rotation.targetAngle", ::ecs.TYPE_FLOAT],
    ["door_operations.lastUseTime", ::ecs.TYPE_FLOAT],
  ]
  comps_ro = [
    ["door_operations.openedAngle", ::ecs.TYPE_FLOAT],
    ["door_operations.closedAngle", ::ecs.TYPE_FLOAT],
    ["rendinst_axis_rotation.curAngle", ::ecs.TYPE_FLOAT],
    ["transform", ::ecs.TYPE_MATRIX],
    ["door_operations.omniRotate", ::ecs.TYPE_BOOL, false],
    ["door_operations.useCooldown", ::ecs.TYPE_FLOAT],
    ["pair_door.eid", ::ecs.TYPE_EID]
  ]
}

local pairDoorQuery = ::ecs.SqQuery("pairDoorQuery", doorComps)

local function toggleDoor(openerTM, comp) {
  local curTime = get_sync_time()
  if (curTime - comp["door_operations.lastUseTime"] < comp["door_operations.useCooldown"])
    return
  comp["door_operations.curState"] = comp["door_operations.closedAngle"] == comp["rendinst_axis_rotation.curAngle"]
  comp["door_operations.reqState"] = !comp["door_operations.reqState"]
  if (comp["door_operations.reqState"]) {
    if (comp["door_operations.omniRotate"]) {
      local openerPos = openerTM ? openerTM.getcol(3) : Point3(0, 0, 0)
      local doorPos = comp.transform.getcol(3)
      local doorDir = comp.transform.getcol(2)
      local sign = (doorDir * (doorPos - openerPos) > 0 ? 1.0 : -1.0) * (comp["door_operations.openedAngle"] - comp["door_operations.closedAngle"] > 0.0 ? 1.0 : -1.0)
      comp["rendinst_axis_rotation.targetAngle"] = comp["door_operations.closedAngle"] + (comp["door_operations.closedAngle"] - comp["door_operations.openedAngle"]) * sign
    }
    else
      comp["rendinst_axis_rotation.targetAngle"] = comp["door_operations.openedAngle"]
  }
  else
    comp["rendinst_axis_rotation.targetAngle"] = comp["door_operations.closedAngle"]
  comp["door_operations.lastUseTime"] = curTime
}

local function onToggleDoor(evt, eid, comp) {
  local openerTM = ::ecs.get_comp_val(evt[0], "transform")
  toggleDoor(openerTM, comp)
  pairDoorQuery.perform(comp["pair_door.eid"], function(qeid, qcomp) {
    toggleDoor(openerTM, qcomp)
  })
}

local function onCmdToggleDoor(evt, eid, comp) {
  local openerTM = ::ecs.get_comp_val(evt.data.openerEid, "transform")
  toggleDoor(openerTM, comp)
  pairDoorQuery.perform(comp["pair_door.eid"], function(qeid, qcomp) {
    toggleDoor(openerTM, qcomp)
  })
}

::ecs.register_es("door_operations_es", {
  [CmdUse] = onToggleDoor,
}, doorComps)

::ecs.register_es("door_toggle_operations_es", {
  [::ecs.sqEvents.CmdToggleDoor] = onCmdToggleDoor,
}, doorComps, {tags="server"})

 