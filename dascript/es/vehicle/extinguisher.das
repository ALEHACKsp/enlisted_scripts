require ecs
require ecs.common
require net
require vehicle
require player
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events

[es (tag=server, no_order)]
def extinguisher_external(info: UpdateStageInfoAct;
                          eid: EntityId;
                          var extinguishable_dot_extinguishTime: float&;
                          maintainable_dot_operator: EntityId;
                          var extinguishable_dot_inProgress: bool&)
  if !maintainable_dot_operator || !extinguishable_dot_inProgress || extinguishable_dot_extinguishTime <= 0.0
    return
  extinguishable_dot_extinguishTime -= info.dt
  if extinguishable_dot_extinguishTime <= 0.0
    sendEventImmediate(eid, [[CmdStopBurn]])
    query(maintainable_dot_operator) <| $[es](var extinguisher_dot_active: bool &)
      extinguisher_dot_active = false
    extinguishable_dot_inProgress = false

def set_extinguishable_state(in_progress: bool;
                             operator_eid: EntityId;
                             target_eid: EntityId;
                             extinguish_time_mult : float = 1.0)
  query(target_eid) <| $[es](var maintainable_dot_operator: EntityId&;
                             var extinguishable_dot_extinguishTime: float&;
                             extinguishable_dot_baseExtinguishTotalTime: float;
                             var extinguishable_dot_extinguishTotalTime: float&;
                             var extinguishable_dot_inProgress: bool&;
                             fire_damage_dot_isBurn: bool)
    if !fire_damage_dot_isBurn
      return
    maintainable_dot_operator = operator_eid
    extinguishable_dot_inProgress = in_progress
    if in_progress && extinguishable_dot_extinguishTime < 0.0
      extinguishable_dot_extinguishTotalTime = extinguishable_dot_baseExtinguishTotalTime * extinguish_time_mult;
      extinguishable_dot_extinguishTime = extinguishable_dot_extinguishTotalTime

[es (tag=server, on_event=CmdActivateExtinguisher)]
def extinguisher_activate(evt: Event;
                          eid: EntityId;
                          maintenance_dot_target: EntityId;
                          entity_mods_dot_vehicleExtinguishTimeMult : float = 1.0;
                          var extinguisher_dot_active: bool&)
  extinguisher_dot_active = true
  set_extinguishable_state(true, eid, maintenance_dot_target, entity_mods_dot_vehicleExtinguishTimeMult)

def stop_extinguisher_impl(var extinguisher_dot_active: bool&; maintenance_dot_target: EntityId)
  set_extinguishable_state(false, INVALID_ENTITY_ID, maintenance_dot_target)
  extinguisher_dot_active = false

[es (tag=server, on_event=CmdStopExtinguisher)]
def extinguisher_stop(evt: Event; var extinguisher_dot_active: bool&; maintenance_dot_target: EntityId)
  stop_extinguisher_impl(extinguisher_dot_active, maintenance_dot_target)

[es (tag=server, after=extinguisher_external)]
def check_extinguishing_restrictions(info: UpdateStageInfoAct;
                                     maintenance_dot_target: EntityId;
                                     var extinguisher_dot_active: bool&;
                                     transform: float3x4;
                                     extinguisher_dot_effectiveDistance: float)
  if !extinguisher_dot_active
    return
  let pos = transform[3]
  var isRestricted = false
  query(maintenance_dot_target) <| $[es](transform: float3x4; isAlive: bool)
    isRestricted = !isAlive || length_sq(transform[3] - pos) > square(extinguisher_dot_effectiveDistance)
  if isRestricted
    stop_extinguisher_impl(extinguisher_dot_active, maintenance_dot_target)

[es (on_event=EventEnterVehicle)]
def stop_extinguishing_on_enter_vehicle(evt: Event;
                                        maintenance_dot_target: EntityId;
                                        var maintenance_dot_hasTarget: bool&;
                                        var extinguisher_dot_active: bool&;
                                        isInVehicle: bool)
  if !extinguisher_dot_active || isInVehicle
    return
  stop_extinguisher_impl(extinguisher_dot_active, maintenance_dot_target)
  maintenance_dot_hasTarget = false
