require ecs
require player
require vehicle
require soundEvent

def is_enable_snapshot(vehicle_eid : ecs::EntityId)
  var isEnable = false
  ecs::query(vehicle_eid) <| $[es](camera_inside_snapshot_enable : bool; camera_inside_snapshot_anyCameraType : bool = false; vehicleCameraType : int = 0)
    if camera_inside_snapshot_enable
      if camera_inside_snapshot_anyCameraType
        isEnable = true
      elif vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_NONE) && vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_COMMANDER)
        isEnable = true
  return isEnable

def snapshot_toggle(vehicle_eid : ecs::EntityId; camera_active : bool; bind_to_vehicle : bool; snapshot_name : string; isCockpitCam : bool; var snapshot_handle : int&)
  let enable = bind_to_vehicle && camera_active && isCockpitCam && is_enable_snapshot(vehicle_eid)
  if enable && snapshot_handle == 0
    snapshot_handle = soundEvent::init(snapshot_name)
    soundEvent::start(snapshot_handle)
  elif !enable && snapshot_handle != 0
    soundEvent::abandon(snapshot_handle)

[es (track=camera_dot_target, track=camera_dot_active, tag=sound)]
def camera_inside_snapshot_toggle_es(evt : Event;
                                     camera_dot_target : ecs::EntityId;
                                     camera_dot_active : bool;
                                     bindToVehicle : bool;
                                     camera_inside_snapshot_dot_name : string;
                                     var camera_inside_snapshot_dot_handle : int&;
                                     isCockpitCam : bool)
  snapshot_toggle(camera_dot_target, camera_dot_active, bindToVehicle, camera_inside_snapshot_dot_name, isCockpitCam, camera_inside_snapshot_dot_handle)

[es (track=vehicleCameraType, REQUIRE=vehicleCameraType, tag=sound)]
def camera_camera_type_toggle_es(evt : Event)
  ecs::query() <| $[es](camera_dot_target : ecs::EntityId;
                        camera_dot_active : bool;
                        bindToVehicle : bool;
                        camera_inside_snapshot_dot_name : string;
                        var camera_inside_snapshot_dot_handle : int&;
                        isCockpitCam : bool)
    snapshot_toggle(camera_dot_target, camera_dot_active, bindToVehicle, camera_inside_snapshot_dot_name, isCockpitCam, camera_inside_snapshot_dot_handle)

[es (on_event=EventEntityDestroyed, tag=sound)]
def camera_inside_snapshot_destroy_es(evt : Event; var camera_inside_snapshot_dot_handle : int&)
  soundEvent::release(camera_inside_snapshot_dot_handle)
