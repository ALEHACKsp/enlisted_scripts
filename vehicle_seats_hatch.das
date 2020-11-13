require ecs
require math.base
require math.ang
require vehicle
require game.utils.hero
require EnlistedHuman
require HumanPhys
require AnimV20

let
  openVel = 5.0f
  timeToClose = 1.0f / openVel
  hatchRot = deg_to_rad(89.0f)

def rotate_hatch_node(var animchar : AnimcharBaseComponent;
                      hatch_dot_node_id : int&;
                      hatch_dot_node_tm : float3x4&;
                      rot_m : float3x4&)
  if hatch_dot_node_id >= 0
    var nodeTm = hatch_dot_node_tm * rot_m
    animchar_set_node_tm(animchar, hatch_dot_node_id, nodeTm)


[es (tag=server, after=after_net_phys_sync)]
def vehicle_seats_hatch_crouch_es(info : UpdateStageInfoAct;
                               vehicle_seats_owners : VehicleSeatsOwners;
                               vehicle_seats_hatch_nodes : VehicleSeatsHatchNodes;
                               var cockpit_dot_isInCockpit : bool&)
  for seatNo in iter_range(vehicle_seats_hatch_nodes.data)
    let owner & = vehicle_seats_owners.data[seatNo]
    let hatch & = vehicle_seats_hatch_nodes.data[seatNo]
    if !hatch.isNodesValid || !owner.isPlayer
      continue
    cockpit_dot_isInCockpit = false
    query(owner.eid) <| $[es](human_net_phys : HumanActor)
      cockpit_dot_isInCockpit = !is_control_bit_set(human_net_phys.phys.appliedCT, (HumanPhysControlType HCT_CROUCH))
    return


[es (after=vehicle_seats_hatch_crouch_es)]
def vehicle_seats_hatch_es(info : UpdateStageInfoAct;
                        cockpit_dot_isInCockpit : bool;
                        vehicle_seats_owners : VehicleSeatsOwners;
                        vehicle_seats_switch_time : VehicleSeatsSwitchTime;
                        var vehicle_seats_hatch_nodes : VehicleSeatsHatchNodes;
                        var vehicle_seats_attach_nodes : VehicleSeatsAttachNodes;
                        var animchar : AnimcharBaseComponent)
  let hero = get_controlled_hero()
  for seatNo in iter_range(vehicle_seats_hatch_nodes.data)
    let owner & = vehicle_seats_owners.data[seatNo]
    let switchTime & = vehicle_seats_switch_time.data[seatNo]
    var hatch & = vehicle_seats_hatch_nodes.data[seatNo]
    var seatAttach & = vehicle_seats_attach_nodes.data[seatNo]
    let isOwnerAlive = get_bool(owner.eid, "isAlive") ?? true
    let isInCockpit = cockpit_dot_isInCockpit
    let isOpen = !!owner.eid && owner.isPlayer && isOwnerAlive && !isInCockpit && hatch.isNodesValid && ((switchTime.time < 0.0f && switchTime.newSeatNo < 0) || switchTime.time > timeToClose)
    if owner.eid == hero && owner.isPlayer
      query() <| $[es](var shooter_cam_dot_alternative_settings : bool&)
        shooter_cam_dot_alternative_settings = hatch.isNodesValid
    if !hatch.isNodesValid
      continue
    hatch.openPos = clamp(hatch.openPos + (isOpen ? 1.0f : -1.0f) * openVel * info.dt, 0.0f, 1.0f)
    let curPos = hatch.openPos
    let trgPos = (isInCockpit ? 0.0f : 1.0f) * hatch.openPos * hatch.maxPos
    let k = clamp((hatch.maxPos - curPos * 2.0f) / hatch.maxPos, 0.0f, 1.0f)
    var pos = seatAttach.initialTm[3]
    pos.y = approach(seatAttach.attachTm[3].y, pos.y + trgPos, info.dt, 0.1f)
    seatAttach.attachTm[3] = pos
    let angles = hatch.rotAxis * (1.0f - k) * hatchRot
    let mRot = make_rot_cw_zyx(angles)
    rotate_hatch_node(animchar, hatch.nodeIdX, hatch.nodeTmX, mRot)
    rotate_hatch_node(animchar, hatch.nodeIdY, hatch.nodeTmY, mRot)


[es (tag=gameClient, track=vehicle_seats_owners)]
def vehicle_seats_hatch_on_change_owner(evt : Event;
                                        vehicle_seats_owners : VehicleSeatsOwners;
                                        vehicle_seats_hatch_nodes : VehicleSeatsHatchNodes)
  let hero = get_controlled_hero()
  for seatNo in iter_range(vehicle_seats_hatch_nodes.data)
    if vehicle_seats_owners.data[seatNo].eid == hero && !vehicle_seats_hatch_nodes.data[seatNo].isNodesValid
      query() <| $[es](var shooter_cam_dot_alternative_settings : bool&)
        shooter_cam_dot_alternative_settings = false
      return