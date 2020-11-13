require ecs
require app
require net
require game.es.vehicle.vehicle_events
require game.es.sound.sound_events

def interrupt_horn(eid : EntityId; var vehicle_horn_dot_horner : EntityId&)
  if vehicle_horn_dot_horner != INVALID_ENTITY_ID
    vehicle_horn_dot_horner = INVALID_ENTITY_ID
    sendEvent(eid, [[CmdVehicleSoundHorn enable=false, end=0.f]])

def get_vehicle_horner(vehicle_eid : EntityId)
  var horner = INVALID_ENTITY_ID;
  query() <| $ [es](isDriver : bool; human_anim_dot_vehicleSelected : EntityId; eid : EntityId)
    if isDriver && human_anim_dot_vehicleSelected == vehicle_eid
      horner = eid
  return horner

[es (tag=server)]
def vehicle_net_horn_request(evt : CmdVehicleHornRequest;
                             eid : EntityId;
                             var vehicle_horn_dot_horner : EntityId&)
  interrupt_horn(eid, vehicle_horn_dot_horner)
  if evt.enable
    vehicle_horn_dot_horner = get_vehicle_horner(eid)
    if vehicle_horn_dot_horner != INVALID_ENTITY_ID
      sendEvent(eid, [[CmdVehicleSoundHorn enable=true, end=(get_sync_time() + 30.0)]])

[es (tag=server, no_order)]
def vehicle_net_horn(info : UpdateStageInfoAct;
                     eid : EntityId;
                     var vehicle_horn_dot_horner : EntityId&)
  if vehicle_horn_dot_horner != INVALID_ENTITY_ID
    var isValid = false
    query(vehicle_horn_dot_horner) <| $ [es](isDriver : bool; human_anim_dot_vehicleSelected : EntityId)
      isValid = isDriver && human_anim_dot_vehicleSelected == eid
    if !isValid
      interrupt_horn(eid, vehicle_horn_dot_horner)
