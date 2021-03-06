require ecs
require game.utils.hero
require vehicle
require game.es.events
require player

def bind_camera_to_vehicle(vehicle: ecs::EntityId; var camera_dot_target: ecs::EntityId&)
  ecs::query(vehicle) <| $[es](vehicleCameraType: int)
    if vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_COMMANDER)
      camera_dot_target = vehicle

def set_camera_target(target: ecs::EntityId;
                      var camera_dot_target: ecs::EntityId&;
                      bindToVehicle: bool)

  camera_dot_target = target

  if bindToVehicle
    ecs::query(target) <| $[es](human_anim_dot_vehicleSelected: ecs::EntityId)
      bind_camera_to_vehicle(human_anim_dot_vehicleSelected, camera_dot_target)

def setup_camera_as_active(cam_eid: EntityId)
  query(get_local_player_eid()) <| $[es](var activeCamEid: EntityId&)
    activeCamEid = cam_eid

[es (track=vehicleCameraType, tag=gameClient)]
def on_change_vehicle_camera_type_es(evt: Event;
                                     vehicleCameraType: int;
                                     vehicleDeathCameraTemplate: string;
                                     var vehicleDeathCamera: ecs::EntityId&;
                                     var vehiclePrevCamera: ecs::EntityId&)

  ecs::query() <| $[es](eid: ecs::EntityId;
                        var camera_dot_target: ecs::EntityId&;
                        var camera_dot_active: bool&;
                        transform: float3x4;
                        bindToVehicle: bool = false)

    if !camera_dot_active
      return

    set_camera_target(get_controlled_hero(), camera_dot_target, bindToVehicle)

    let setupCameraAsActive <- @ <| (cam_eid: EntityId)
      setup_camera_as_active(cam_eid)
    if vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_DEAD) && vehicleDeathCamera == INVALID_ENTITY_ID
      camera_dot_active = false
      vehiclePrevCamera = eid
      vehicleDeathCamera = createEntity(vehicleDeathCameraTemplate, setupCameraAsActive) <| $ (var init: ComponentsInitializer)
        set(init, "camera.target", camera_dot_target)
        set(init, "camera.active", true)
        set(init, "transform", transform)
    elif vehicleCameraType != int(VehicleCameraType VEHICLE_CAMERA_DEAD) && vehicleDeathCamera != INVALID_ENTITY_ID
      destroyEntity(vehicleDeathCamera)
      let switchToPrevCam = (get_Eid(get_local_player_eid(), "activeCamEid") ?? INVALID_ENTITY_ID) == vehicleDeathCamera
      vehicleDeathCamera = INVALID_ENTITY_ID

      if switchToPrevCam
        ecs::query(vehiclePrevCamera) <| $[es](var camera_dot_target: ecs::EntityId&; var camera_dot_active: bool&; bindToVehicle: bool = false)
          camera_dot_active = true
          setup_camera_as_active(vehiclePrevCamera)
          set_camera_target(get_controlled_hero(), camera_dot_target, bindToVehicle)

      vehiclePrevCamera = INVALID_ENTITY_ID

[es (tag=gameClient)]
def set_camera_target_es(evt: CmdSetCameraTarget; var camera_dot_target: ecs::EntityId&; bindToVehicle: bool = false)
  set_camera_target(evt.target, camera_dot_target, bindToVehicle)

// This is workaround for camera binding bug.
// Camera with bindToVehicle == true must be binded to the vehicle,
// but when camera is created on the client the vehicle is not available yet.
// So, the camera stayes attached to the human.
// This polling solves the problem, but must be removed in the future.
// Polling is a bad way to solve issues.
[es (tag=gameClient, no_order)]
def fix_camera_target_es(info: UpdateStageInfoAct; eid: EntityId; var camera_dot_target: ecs::EntityId&; bindToVehicle: bool)
  if bindToVehicle && !has(camera_dot_target, "vehicle")
    find_query() <| $[es](bindedCamera: EntityId; human_anim_dot_vehicleSelected: ecs::EntityId)
      if bindedCamera == eid
        bind_camera_to_vehicle(human_anim_dot_vehicleSelected, camera_dot_target)
        return true
      return false
