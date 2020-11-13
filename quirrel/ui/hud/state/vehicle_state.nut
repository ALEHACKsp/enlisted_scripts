  
                                                         
                                                                                                   

     
                                                
  

local {get_sync_time} = require("net")

local inTank = Watched(false)
local inPlane = Watched(false)
local inGroundVehicle = Watched(false)

local state = {
  isDriver = Watched(false)
  isGunner = Watched(false)
  isExtinguishing = Watched(false)
  isRepairing = Watched(false)

  maintenanceTarget = Watched(INVALID_ENTITY_ID)
  vehicleRepairTime = Watched(null)
  maintenanceTime = Watched(0.0)
  maintenanceTotalTime = Watched(0.0)
  controlledVehicleEid = Watched(INVALID_ENTITY_ID)
  vehicleEngineBroken = Watched(false)
  vehicleTracksBroken = Watched(false)
  vehicleWheelsBroken = Watched(false)
  vehicleTransmissionBroken = Watched(false)
  vehicleTurretHorDriveBroken = Watched(false)
  vehicleTurretVerDriveBroken = Watched(false)
  vehicleReloadProgress = Watched(null)
  inGroundVehicle = inGroundVehicle
  inPlane = inPlane
  inTank = inTank
  isAutomaticTransmission = Watched(false)
  gear = Watched(0)
  neutralGear = Watched(0)
  rpm = Watched(0)
  cruiseControl = Watched(0)
  speed = Watched(0)
  planeTas = Watched(0.0)
}
state.inVehicle <- ::Computed(@() inGroundVehicle.value || inPlane.value)

::ecs.register_es("ui_vehicle_state_es",
  {[["onChange", "onInit"]] = function trackChanges(evt, eid, comp){
      state.vehicleReloadProgress(comp["vehicleReloadProgress"])
    }
  },
  {
    comps_track = [["vehicleReloadProgress", ::ecs.TYPE_FLOAT]]
    comps_rq=["watchedByPlr"]
  }
)

::ecs.register_es("ui_in_vehicle_eid_es",
  {
    [["onChange", "onInit"]] = function (evt, eid, comp) {
      state.controlledVehicleEid(eid)
      local inPlaneC = comp["airplane"] != null
      local inTankC = comp["isTank"] != null
      local wheelDestroyedCount = comp["vehicle.destroyedWheelsCountWarn"]
      state.inPlane(inPlaneC)
      state.inGroundVehicle(!inPlaneC)
      state.inTank(inTankC)
      local isPartDead = @(partId) comp.dm_state[partId] == 0
      foreach (idx in (comp["dm_phys_parts.enginePartIds"]?.getAll() ?? [])) {
        if (isPartDead(idx)){
          state.vehicleEngineBroken(true)
          break
        }
      }
      foreach (idx in (comp["dm_phys_parts.transmissionPartIds"]?.getAll() ?? [])) {
        if (isPartDead(idx)){
          state.vehicleTransmissionBroken(true)
          break
        }
      }
      foreach (idx in (comp["dm_phys_parts.tracksPartIds"]?.getAll() ?? [])) {
        if (isPartDead(idx)){
          state.vehicleTracksBroken(true)
          break
        }
      }
      foreach (idx in (comp["dm_phys_parts.wheelsPartIds"]?.getAll() ?? [])) {
        if (isPartDead(idx)){
          wheelDestroyedCount--
          if (wheelDestroyedCount <= 0){
            state.vehicleWheelsBroken(true)
            break
          }
        }
      }
      foreach (idx in (comp["turret_drive_dm_part.horDriveDm"]?.getAll() ?? [])) {
        if (isPartDead(idx)){
          state.vehicleTurretHorDriveBroken(true)
          break
        }
      }
      foreach (idx in (comp["turret_drive_dm_part.verDriveDm"]?.getAll() ?? [])) {
        if (isPartDead(idx)){
          state.vehicleTurretVerDriveBroken(true)
          break
        }
      }
      state.isAutomaticTransmission(comp["vehicle.isAutomaticTransmission"])
      state.gear(comp["vehicle.gear"])
      state.neutralGear(comp["vehicle.neutralGear"])
      state.rpm(comp["vehicle.rpm"])
      state.cruiseControl(comp["vehicle.cruiseControl"])
      state.speed(comp["vehicle.speed"])
      state.planeTas(comp["plane_view.tas"])
    },
    function onDestroy(evt, eid, comp){
      state.inPlane(false)
      state.inGroundVehicle(false)
      state.inTank(false)
      state.controlledVehicleEid(INVALID_ENTITY_ID)
      state.vehicleTracksBroken(false)
      state.vehicleWheelsBroken(false)
      state.vehicleTransmissionBroken(false)
      state.vehicleEngineBroken(false)
      state.vehicleTurretHorDriveBroken(false)
      state.vehicleTurretVerDriveBroken(false)
      state.isAutomaticTransmission(false)
      state.gear(0)
      state.neutralGear(0)
      state.rpm(0)
      state.cruiseControl(0)
      state.speed(0)
      state.planeTas(0.0)
    }
  },
  {
    comps_track = [
      ["dm_phys_parts.enginePartIds", ::ecs.TYPE_INT_LIST, null],
      ["dm_phys_parts.transmissionPartIds", ::ecs.TYPE_INT_LIST, null],
      ["dm_phys_parts.tracksPartIds", ::ecs.TYPE_INT_LIST, null],
      ["dm_phys_parts.wheelsPartIds", ::ecs.TYPE_INT_LIST, null],
      ["turret_drive_dm_part.horDriveDm", ::ecs.TYPE_INT_LIST, null],
      ["turret_drive_dm_part.verDriveDm", ::ecs.TYPE_INT_LIST, null],
      ["vehicle.isAutomaticTransmission", ::ecs.TYPE_BOOL, false],
      ["vehicle.gear", ::ecs.TYPE_INT, 0],
      ["vehicle.neutralGear", ::ecs.TYPE_INT, 0],
      ["vehicle.rpm", ::ecs.TYPE_INT, 0],
      ["vehicle.cruiseControl", ::ecs.TYPE_INT, 0],
      ["vehicle.speed", ::ecs.TYPE_INT, 0],
      ["plane_view.tas", ::ecs.TYPE_FLOAT, 0.0],
      ["dm_state", ::ecs.TYPE_UINT16_LIST],
    ],
    comps_ro = [
      ["airplane", ::ecs.TYPE_TAG, null],
      ["isTank", ::ecs.TYPE_TAG, null],
      ["vehicle.destroyedWheelsCountWarn", ::ecs.TYPE_INT, 0]
    ],
    comps_rq=["vehicleWithWatched"]
  }
)

local maintenanceTargetQuery = ::ecs.SqQuery("maintenanceTargetQuery", {
  comps_ro = [
    ["repairable.repairTotalTime", ::ecs.TYPE_FLOAT, -1.0],
    ["repairable.repairTime", ::ecs.TYPE_FLOAT, -1.0],
    ["extinguishable.extinguishTotalTime", ::ecs.TYPE_FLOAT, -1.0],
    ["extinguishable.extinguishTime", ::ecs.TYPE_FLOAT, -1.0],
    ["extinguishable.inProgress", ::ecs.TYPE_BOOL, false],
    ["repairable.inProgress", ::ecs.TYPE_BOOL, false],
  ]
})
::ecs.register_es("ui_maintenance_es",
  {
    [["onChange", "onInit"]] = function (evt, eid, comp) {
      local isHeroExtinguishing = comp["extinguisher.active"]
      local isHeroRepairing = comp["repair.active"]
      local mntTgtEid = comp["maintenance.target"]

      state.maintenanceTarget(mntTgtEid)
      state.isExtinguishing(isHeroExtinguishing)
      state.isRepairing(isHeroRepairing)
      if (mntTgtEid != INVALID_ENTITY_ID){
        maintenanceTargetQuery.perform(mntTgtEid, function(eid, comp){
          state.vehicleRepairTime((comp["repairable.inProgress"] && isHeroRepairing) ? comp["repairable.repairTime"] : null)
          if (comp["extinguishable.inProgress"] && isHeroExtinguishing) {
            state.maintenanceTime(comp["extinguishable.extinguishTime"] + get_sync_time())
            state.maintenanceTotalTime(comp["extinguishable.extinguishTotalTime"])
          } else if (comp["repairable.inProgress"] && isHeroRepairing) {
            state.maintenanceTime(comp["repairable.repairTime"] + get_sync_time())
            state.maintenanceTotalTime(comp["repairable.repairTotalTime"])
          } else {
            state.maintenanceTime(0.0)
            state.maintenanceTotalTime(0.0)
          }
        })
      }
    },
    function onDestroy(...){
      state.maintenanceTarget(INVALID_ENTITY_ID)
      state.vehicleRepairTime(null)
      state.maintenanceTime(0.0)
      state.isRepairing(false)
      state.isExtinguishing(false)
    }
  },
  {
    comps_track = [
      ["maintenance.target", ::ecs.TYPE_EID],
      ["extinguisher.active", ::ecs.TYPE_BOOL, false],
      ["repair.active", ::ecs.TYPE_BOOL, false]
    ],
    comps_rq=["watchedByPlr"]
  }
)

::ecs.register_es("ui_vehicle_role_es",
  {
    [["onChange", "onInit"]] = function (evt, eid, comp) {
      state.isDriver(comp["isDriver"] && comp["isInVehicle"])
      state.isGunner(comp["isGunner"] && comp["isInVehicle"])
    },
    function onDestroy(evt, eid, comp) {
      state.isDriver(false)
      state.isGunner(false)
    }
  },
  {
    comps_track = [
      ["isInVehicle", ::ecs.TYPE_BOOL, false],
      ["isDriver", ::ecs.TYPE_BOOL, false],
      ["isGunner", ::ecs.TYPE_BOOL, false],
    ],
    comps_rq = ["watchedByPlr"]
  }
)

return state 