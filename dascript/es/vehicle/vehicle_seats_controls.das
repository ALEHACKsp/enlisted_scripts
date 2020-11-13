require ecs
require ecs.common
require strings
require net
require game.es.events
require game.es.vehicle.vehicle_events
require DagorSystem
require game.utils.hero
require game.utils.team
require game.utils.net_utils
require EnlistedActor
require EnlistedHuman
require vehicle

def recreate_vehicle(vehicle_eid: EntityId; phys_actor: BasePhysActor; mode: VehicleControlsState)
  var heroComponents = "+"
  heroComponents += phys_actor.physTypeStr;
  heroComponents += "_hero_components"
  var controlComponents = "+"
  controlComponents += phys_actor.physTypeStr;
  controlComponents += "_control_components"
  var templName = getEntityTemplateName(vehicle_eid)
  templName = replace(templName, heroComponents, "")
  templName = replace(templName, controlComponents, "")
  templName = replace(templName, "+turret_control_components", "")
  templName = replace(templName, "+camera_control_components", "")
  if mode.canControlVehicleOrTurrets
    templName += heroComponents
  if mode.canControlVehicle
    templName += controlComponents
  if int(mode.turretsMask) != 0
    templName += "+turret_control_components"
  if mode.canControlCamera
    templName += "+camera_control_components"
  reCreateEntityFrom(vehicle_eid, templName)

def stop_vehicle_control(var phys_actor: BasePhysActor&)
  phys_actor |> base_phys_actor_init_role()
  phys_actor |> base_phys_actor_reset_aas() // Don't try to process too old AAS when we control this vehicle again
  phys_actor |> base_phys_actor_reset()

def stop_vehicle_control_server(var phys_actor: BasePhysActor&)
  stop_vehicle_control(phys_actor)
  base_phys_actor_set_tickrate_type(phys_actor, phys_actor.role, PhysTickRateType LowFreq)

def determine_controls_for_player(current_owner, vehicle_seats_controls, vehicle_seats_owners, vehicle_seats_player_camera_types, can_acquire_controls)
  var mode: VehicleControlsState
  if !(get_bool(current_owner.eid, "isAlive") ?? false)
    return mode

  let seatsCount = length(vehicle_seats_owners.data)
  for seatNo in range(0, seatsCount)
    let owner & = vehicle_seats_owners.data[seatNo]
    if owner.player == current_owner.player && (get_bool(owner.eid, "isAlive") ?? false)
      let control & = vehicle_seats_controls.data[seatNo]
      if (can_acquire_controls & int(VehicleControlTypes VEHICLE_CONTROLS_MOVEMENT)) != 0
        mode.canControlVehicle ||= control.canControlVehicle
      if (can_acquire_controls & int(VehicleControlTypes VEHICLE_CONTROLS_TURRETS)) != 0
        mode.turretsMask = uint16(int(mode.turretsMask) | int(control.turretsMask))
      if (can_acquire_controls & int(VehicleControlTypes VEHICLE_CONTROLS_CAMERA)) != 0
        mode.canControlCamera = true

  for seatNo in range(0, seatsCount)
    let owner & = vehicle_seats_owners.data[seatNo]
    if owner.isPlayer && vehicle_seats_owners.data[seatNo].eid == current_owner.eid
      let cameraType = vehicle_seats_player_camera_types[seatNo]
      if (cameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER_COCKPIT) ||
          cameraType == int(VehicleCameraType VEHICLE_CAMERA_GUNNER_COCKPIT))
        mode.turretsMask = uint16(0)
      break

  return mode

def find_owner_player_for_vehicle(vehicle_seats_player_controls: VehicleSeatsPlayerControls;
                                  vehicle_seats_owners: VehicleSeatsOwners): EntityId
  for seatNo in iter_range(vehicle_seats_owners.data)
    let control & = vehicle_seats_player_controls.data[seatNo]
    if control.canControlVehicle
      return vehicle_seats_owners.data[seatNo].player
  return INVALID_ENTITY_ID

[es (tag=server, no_order)]
def vehicle_seats_update_controls(info: UpdateStageInfoAct;
                                  eid: EntityId;
                                  vehicle_seats_owners: VehicleSeatsOwners;
                                  vehicle_seats_controls: VehicleSeatsControls;
                                  vehicle_seats_can_acquire_controls: IntList ?;
                                  var vehicle_seats_player_controls: VehicleSeatsPlayerControls&;
                                  var vehicle_controls_state: VehicleControlsState&;
                                  vehicle_seats_player_camera_types: IntList;
                                  vehicle_seats_dot_autoDetectRestrictToTeam: bool = false;
                                  var vehicle_seats_dot_restrictToTeam: int?;
                                  replication: NetObject?)
  if vehicle_seats_dot_restrictToTeam != null && vehicle_seats_dot_autoDetectRestrictToTeam
    *vehicle_seats_dot_restrictToTeam = TEAM_UNASSIGNED
  var vehicleMode: VehicleControlsState
  for seatNo in iter_range(vehicle_seats_owners.data)
    let owner& = vehicle_seats_owners.data[seatNo]
    var control& = vehicle_seats_player_controls.data[seatNo]
    if owner.eid == INVALID_ENTITY_ID || !owner.isPlayer
      control.turretsMask = uint16(0)
      control.canControlVehicle = false
      continue
    if vehicle_seats_dot_restrictToTeam != null && vehicle_seats_dot_autoDetectRestrictToTeam
      *vehicle_seats_dot_restrictToTeam = get_int(owner.eid, "team") ?? TEAM_UNASSIGNED
    let canAcquireControls = (vehicle_seats_can_acquire_controls != null
      ? (*vehicle_seats_can_acquire_controls)[seatNo]
      : int(VehicleControlTypes VEHICLE_CONTROLS_MOVEMENT))
    let playerMode = determine_controls_for_player(owner, vehicle_seats_controls,
                                                   vehicle_seats_owners, vehicle_seats_player_camera_types,
                                                   canAcquireControls)
    vehicleMode.canControlVehicle ||= playerMode.canControlVehicle
    vehicleMode.turretsMask = uint16(int(vehicleMode.turretsMask) | int(playerMode.turretsMask))
    control = playerMode
  let playerEid: EntityId = find_owner_player_for_vehicle(vehicle_seats_player_controls, vehicle_seats_owners)
  let connid = get_int(playerEid, "connid") ?? INVALID_CONNECTION_ID
  let conn: net::IConnection ? = (connid != INVALID_CONNECTION_ID) ? get_client_connection(connid) : null
  let isOwnerChanged: bool = (replication != null && vehicleMode.canControlVehicle &&
                              (playerEid != INVALID_ENTITY_ID) &&
                              conn != null && net_object_get_controlled_by(replication) != connection_get_id(conn))
  if vehicle_controls_state != vehicleMode || isOwnerChanged
    vehicle_controls_state = vehicleMode
    if replication == null
      return
    if playerEid != INVALID_ENTITY_ID && conn != null && vehicleMode.canControlVehicle
      if net_object_get_controlled_by(replication) == INVALID_CONNECTION_ID || isOwnerChanged
        net_object_set_controlled_by(replication,connection_get_id(conn))
    else
      net_object_set_controlled_by(replication, INVALID_CONNECTION_ID)
    let isOwner: bool = (playerEid != INVALID_ENTITY_ID && conn != null &&
                         net_object_get_controlled_by(replication) == connection_get_id(conn))
    var physActor: BasePhysActor ? = get_phys_actor(eid)
    if physActor == null
      return
    if isOwner && vehicleMode.canControlVehicle
      base_phys_actor_set_role_and_tickrate_type(physActor, NetRole ROLE_REMOTELY_CONTROLLED_AUTHORITY,
        PhysTickRateType Normal)
    if !vehicleMode.canControlVehicle || !vehicleMode.canControlVehicleOrTurrets
      stop_vehicle_control_server(*physActor)

[es (tag=gameClient, no_order)]
def vehicle_seats_apply_controls(info: UpdateStageInfoAct;
                                 eid: EntityId;
                                 vehicle_seats_owners: VehicleSeatsOwners;
                                 vehicle_seats_player_controls: VehicleSeatsPlayerControls;
                                 var local_controls_state: VehicleControlsState&;
                                 replication: NetObject?)
  let hero = get_controlled_hero()
  var mode: VehicleControlsState
  for seatNo in iter_range(vehicle_seats_owners.data)
    let owner& = vehicle_seats_owners.data[seatNo]
    let control& = vehicle_seats_player_controls.data[seatNo]
    if owner.eid == hero
      mode = control
      break
  if local_controls_state != mode
    if replication != null
      if mode.canControlVehicle
        let sconn: net::IConnection ? = get_server_conn()
        if sconn != null
          net_object_set_controlled_by(replication, connection_get_id(sconn))
      else
        net_object_set_controlled_by(replication, INVALID_CONNECTION_ID)
    var physActor: BasePhysActor? = get_phys_actor(eid)
    if physActor == null
      return
    if mode.canControlVehicle
      let nr: NetRole = (is_server()
        ? NetRole ROLE_LOCALLY_CONTROLLED_AUTHORITY
        : NetRole ROLE_LOCALLY_CONTROLLED_SHADOW)
      base_phys_actor_set_role_and_tickrate_type(physActor, nr, PhysTickRateType Normal)
    if int(mode.turretsMask) != 0
      if !mode.canControlVehicle
        stop_vehicle_control(*physActor)
      query(hero) <| $[es](human_net_phys: HumanActor)
        let ct & = human_net_phys.phys.producedCT
        sendEventImmediate(eid, [[CmdSetVehicleShootDir dir = ct.wishShootDir]])
    local_controls_state = mode
    if !mode.canControlVehicleOrTurrets
      stop_vehicle_control(*physActor)
    recreate_vehicle(eid, *physActor, mode)

[es (tag=gameClient, track=cockpit_dot_currentSlit, after=vehicle_cockpit_on_slit_change, on_event=EventEntityCreated)]
def vehicle_cockpit_detect_machinegunner(evt: Event;
                                         cockpit_dot_vehicleEid: EntityId;
                                         cockpit_dot_currentSlit: int;
                                         cockpit_dot_slitIsGun: BoolList)
  query(cockpit_dot_vehicleEid) <| $[es](var cockpit_dot_isGunner: bool&)
    cockpit_dot_isGunner = cockpit_dot_slitIsGun[cockpit_dot_currentSlit]

[es (tag=gameClient, track=cockpit_dot_isGunner)]
def vehicle_on_change_cockpit_machinegunner(evt: Event; eid: EntityId; cockpit_dot_isGunner: bool)
  sendEvent(eid, [[CmdSetGunnerCockpitRequest isGunner=cockpit_dot_isGunner]])

[es (tag=server)]
def vehicle_cockpit_set_machinegunner(evt: CmdSetGunnerCockpitRequest; var cockpit_dot_isGunner: bool&)
  cockpit_dot_isGunner = evt.isGunner

def detect_camera_type(owner, wishCamera, isInCockpit, isGunner)
  let isAlive = get_bool(owner, "isAlive") ?? true
  if !isAlive
    return int(VehicleCameraType VEHICLE_CAMERA_DEAD)

  if wishCamera == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER) && isInCockpit
    return isGunner ? int(VehicleCameraType VEHICLE_CAMERA_MACHINEGUNNER_COCKPIT) : int(VehicleCameraType VEHICLE_CAMERA_COMMANDER_COCKPIT)

  if wishCamera == int(VehicleCameraType VEHICLE_CAMERA_GUNNER) && !isGunner
    return int(VehicleCameraType VEHICLE_CAMERA_GUNNER_COCKPIT)

  return wishCamera

[es (no_order)]
def vehicle_seats_detect_camera_type(info: UpdateStageInfoAct;
                                     vehicle_seats_owners: VehicleSeatsOwners;
                                     vehicle_seats_camera_types: IntList;
                                     cockpit_dot_isInCockpit: bool;
                                     cockpit_dot_isGunner: bool;
                                     var vehicle_seats_player_camera_types: IntList)
  let vehicleCameraType = int(VehicleCameraType VEHICLE_CAMERA_NONE)
  for seatNo in iter_range(vehicle_seats_owners.data)
    let owner& = vehicle_seats_owners.data[seatNo]
    let cameraType = owner.isPlayer ? detect_camera_type(owner.eid, vehicle_seats_camera_types[seatNo], cockpit_dot_isInCockpit, cockpit_dot_isGunner) : int(VehicleCameraType VEHICLE_CAMERA_NONE)
    vehicle_seats_player_camera_types[seatNo] = cameraType

[es (tag=gameClient, after=vehicle_seats_detect_camera_type, REQUIRE=heroVehicle)]
def vehicle_seats_apply_camera_type(info: UpdateStageInfoAct;
                                    vehicle_seats_owners: VehicleSeatsOwners;
                                    vehicle_seats_player_camera_types: IntList;
                                    var vehicleCameraType: int&)
  for seatNo in iter_range(vehicle_seats_owners.data)
    let owner& = vehicle_seats_owners.data[seatNo]

    if !owner.isPlayer || !has(owner.eid, "hero")
      continue

    let cameraType = vehicle_seats_player_camera_types[seatNo]
    vehicleCameraType = cameraType

    query(owner.eid) <| $[es](isTpsView: bool; var vehicleCameraType: int&)
      vehicleCameraType = isTpsView ? int(VehicleCameraType VEHICLE_CAMERA_NONE) : cameraType

[es (tag=gameClient, on_event=EventComponentsDisappear, REQUIRE=heroVehicle)]
def vehicle_seats_reset_camera_type(evt: Event; var vehicleCameraType: int&)
  vehicleCameraType = int(VehicleCameraType VEHICLE_CAMERA_NONE)
