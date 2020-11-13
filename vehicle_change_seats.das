require ecs
require ecs.common
require app
require net
require vehicle
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events
require DagorSystem
require game.utils.hero

[es (tag=server, REQUIRE=vehicle_seats_dot_seats)]
def vehicle_seats_switch_seat_request(evt: RequestVehicleChangeSeat; eid: EntityId)
  sendEvent(eid, [[CmdVehicleChangeSeat eid=evt.eid, seat=evt.seat]])

def start_seat_timer(sitter_eid : EntityId;
                     cur_seat_no: int;
                     new_seat_no: int;
                     var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                     vehicle_seats_switch_time_dot_totalSwitchTime: float)
  if new_seat_no < 0
    return
  var times & = vehicle_seats_switch_time.data
  var switchTimeData & = times[cur_seat_no]
  if new_seat_no == cur_seat_no || switchTimeData.time > 0.f
    return
  let switchMult = get_float(sitter_eid, "entity_mods.vehicleChangeSeatTimeMult") ?? 1.0
  let switchTime = vehicle_seats_switch_time_dot_totalSwitchTime * switchMult
  switchTimeData.time = switchTime
  switchTimeData.newSeatNo = new_seat_no

def get_seat_no(sitter_eid: EntityId; vehicle_seats_owners: VehicleSeatsOwners): int
  var index = -1
  let owners & = vehicle_seats_owners.data
  index = find_index_if(owners) <| $ (owner) : bool
    return owner.eid == sitter_eid
  return index

[es (tag=server)]
def vehicle_seats_switch_seat(evt: CmdVehicleChangeSeat;
                              vehicle_seats_owners: VehicleSeatsOwners;
                              var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                              vehicle_seats_switch_time_dot_totalSwitchTime: float)
  let sitterEid = evt.eid
  let newSeatNo = evt.seat
  if newSeatNo < 0
    return
  let curSeatNo = get_seat_no(sitterEid, vehicle_seats_owners)
  if curSeatNo < 0
    return
  start_seat_timer(sitterEid, curSeatNo, newSeatNo, vehicle_seats_switch_time, vehicle_seats_switch_time_dot_totalSwitchTime)

def request_seat_switch(sitter_eid: EntityId;
                        seat_order_no: int;
                        vehicle_seats_order: VehicleSeatsOrder;
                        vehicle_seats_owners: VehicleSeatsOwners;
                        var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                        vehicle_seats_switch_time_dot_totalSwitchTime: float): bool
  var requested = false
  let orders & = vehicle_seats_order.data
  if seat_order_no < 0 || length(orders) <= seat_order_no || !orders[seat_order_no].canPlaceManually
    return requested
  let newSeatNo = orders[seat_order_no].seatNo
  if newSeatNo < 0
    return requested
  let curSeatNo = get_seat_no(sitter_eid, vehicle_seats_owners)
  if curSeatNo < 0
    return requested
  start_seat_timer(sitter_eid, curSeatNo, newSeatNo, vehicle_seats_switch_time, vehicle_seats_switch_time_dot_totalSwitchTime)
  requested = true
  return requested

def can_change_seat_to(seat_order_no: int;
                       vehicle_seats_order: VehicleSeatsOrder;
                       vehicle_seats_owners: VehicleSeatsOwners): bool
  var canChange = false
  let orders & = vehicle_seats_order.data
  if seat_order_no < 0 || seat_order_no >= length(orders)
    return canChange
  let order & = orders[seat_order_no]
  if !order.canPlaceManually
    return canChange
  let seatNo = order.seatNo
  let owners & = vehicle_seats_owners.data
  let owner & = owners[seatNo]
  canChange = !owner.eid || !owner.isPlayer
  return canChange

def change_seat_or_switch_squad_leader(seat_order_no: int;
                                       sitter_eid: EntityId;
                                       vehicle_seats_order: VehicleSeatsOrder;
                                       vehicle_seats_owners: VehicleSeatsOwners;
                                       change_leader: block<(squad_eid, member_eid: EntityId)>)
  var shouldChangeVehicleSeat = false
  var shouldSwitchSquadLeader = false
  var switchToMember: EntityId;
  let owners & = vehicle_seats_owners.data
  let orders & = vehicle_seats_order.data
  if sitter_eid == get_controlled_hero() && can_change_seat_to(seat_order_no, vehicle_seats_order, vehicle_seats_owners)
    let seatNo = orders[seat_order_no].seatNo
    let owner & = owners[seatNo]
    shouldSwitchSquadLeader = (owner.player == (get_Eid(sitter_eid, "possessedByPlr") ?? INVALID_ENTITY_ID)
      && (get_bool(owner.eid, "isAlive") ?? false))
    switchToMember = owner.eid
    shouldChangeVehicleSeat = !shouldSwitchSquadLeader
  if shouldSwitchSquadLeader
    let squadEid = get_Eid(sitter_eid, "squad_member.squad") ?? INVALID_ENTITY_ID
    invoke(change_leader, squadEid, switchToMember)
  elif shouldChangeVehicleSeat
    broadcastEvent([[EventOnStartVehicleChangeSeat eid=sitter_eid, seat=orders[seat_order_no].seatNo]])

  return shouldChangeVehicleSeat

[es (tag=server)]
def vehicle_seats_switch_seat_place(evt: CmdVehiclePlaceSeat;
                                    vehicle_seats_order: VehicleSeatsOrder;
                                    vehicle_seats_owners: VehicleSeatsOwners;
                                    var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                                    vehicle_seats_switch_time_dot_totalSwitchTime: float)
  let sitterEid = evt.eid
  let seatOrderNo = evt.seat
  let shouldChangeVehicleSeat = change_seat_or_switch_squad_leader(seatOrderNo, sitterEid, vehicle_seats_order,
                                                                   vehicle_seats_owners) <| $(squad_eid, member_eid)
    sendEvent(squad_eid, [[CmdSwitchSquadLeader eid=member_eid]])
  if shouldChangeVehicleSeat
    request_seat_switch(sitterEid, seatOrderNo, vehicle_seats_order,
                        vehicle_seats_owners, vehicle_seats_switch_time, vehicle_seats_switch_time_dot_totalSwitchTime)

def get_vehicle_control_seat(vehicle_seats_controls: VehicleSeatsControls): int
  var seatNo = -1
  let controls & = vehicle_seats_controls.data
  for index in iter_range(controls)
    if controls[index].canControlVehicleOnly
      seatNo = index
      break
  return seatNo

[es (tag=server)]
def vehicle_seats_switch_driver_seat(evt: CmdVehiclePlaceDriverSeat;
                                     vehicle_seats_controls: VehicleSeatsControls;
                                     vehicle_seats_order: VehicleSeatsOrder;
                                     vehicle_seats_owners: VehicleSeatsOwners;
                                     var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                                     vehicle_seats_switch_time_dot_totalSwitchTime: float)
  let sitterEid = evt.eid
  let seatOrderNo = get_vehicle_control_seat(vehicle_seats_controls)
  request_seat_switch(sitterEid, seatOrderNo, vehicle_seats_order,
                      vehicle_seats_owners, vehicle_seats_switch_time, vehicle_seats_switch_time_dot_totalSwitchTime)

def send_change_seat_net_msg(vehicle_eid: EntityId;
                             sitter_eid: EntityId;
                             seat_order_no: int;
                             vehicle_seats_order: VehicleSeatsOrder): bool
  var seatNo = -1
  let orders & = vehicle_seats_order.data
  if seat_order_no >= 0 && length(orders) > seat_order_no && orders[seat_order_no].canPlaceManually
    seatNo = orders[seat_order_no].seatNo
  if seatNo < 0
    return false
  sendEvent(vehicle_eid, [[RequestVehicleChangeSeat eid=sitter_eid, seat=seatNo]])
  return true

[es (tag=gameClient, REQUIRE=replication)]
def vehicle_seats_switch_seat_requester(evt: CmdVehiclePlaceSeat;
                                        eid: EntityId;
                                        vehicle_seats_order: VehicleSeatsOrder;
                                        vehicle_seats_owners: VehicleSeatsOwners)
  let sitterEid = evt.eid
  let seatOrderNo = evt.seat
  let shouldChangeVehicleSeat = change_seat_or_switch_squad_leader(seatOrderNo, sitterEid, vehicle_seats_order,
                                                                   vehicle_seats_owners) <| $(squad_eid, member_eid)
    sendEvent(squad_eid, [[RequestSquadChangeLeader eid=member_eid]])
  if shouldChangeVehicleSeat
    send_change_seat_net_msg(eid, sitterEid, seatOrderNo, vehicle_seats_order)

[es (tag=gameClient, REQUIRE=replication)]
def vehicle_seats_request_driver_seat(evt: CmdVehiclePlaceDriverSeat;
                                      eid: EntityId;
                                      vehicle_seats_controls: VehicleSeatsControls;
                                      vehicle_seats_order: VehicleSeatsOrder)
  let sitterEid = evt.eid
  let seatOrderNo = get_vehicle_control_seat(vehicle_seats_controls)
  send_change_seat_net_msg(eid, sitterEid, seatOrderNo, vehicle_seats_order)

def find_next_seat(vehicle_seats_next_seats: IntList;
                   vehicle_seats_owners: VehicleSeatsOwners;
                   human_eid: EntityId): int
  var nextSeat = -1
  let owners & = vehicle_seats_owners.data
  for seatNo in iter_range(vehicle_seats_next_seats)
    if owners[seatNo].eid == human_eid
      var nextSeatNo = vehicle_seats_next_seats[seatNo]
      if nextSeatNo < 0
        break
      while true
        if nextSeatNo == seatNo
          break
        if owners[nextSeatNo].eid == INVALID_ENTITY_ID
          nextSeat = nextSeatNo
          break
        else
          nextSeatNo = vehicle_seats_next_seats[nextSeatNo]
  return nextSeat

[es (tag=gameClient, REQUIRE=replication, REQUIRE=vehicle_seats_dot_seats)]
def vehicle_seats_switch_seat_requester_next(evt: CmdVehiclePlaceNextSeat;
                                             vehicle_seats_next_seats: IntList;
                                             vehicle_seats_owners: VehicleSeatsOwners;
                                             eid: EntityId)
  let sitterEid = evt.eid
  let seatNo = find_next_seat(vehicle_seats_next_seats, vehicle_seats_owners, sitterEid)
  if seatNo < 0
    return
  sendEvent(eid, [[RequestVehicleChangeSeat eid=sitterEid, seat=seatNo]])

[es (tag=server)]
def vehicle_seats_switch_seat_next(evt: CmdVehiclePlaceNextSeat;
                                   vehicle_seats_next_seats: IntList;
                                   vehicle_seats_owners: VehicleSeatsOwners;
                                   var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                                   vehicle_seats_switch_time_dot_totalSwitchTime: float)
  let sitterEid = evt.eid
  let newSeatNo = find_next_seat(vehicle_seats_next_seats, vehicle_seats_owners, sitterEid)
  let curSeatNo = get_seat_no(sitterEid, vehicle_seats_owners)
  if newSeatNo < 0 || curSeatNo < 0
    return
  start_seat_timer(sitterEid, curSeatNo, newSeatNo, vehicle_seats_switch_time, vehicle_seats_switch_time_dot_totalSwitchTime)

def swap_seats(seat1: int; seat2: int;
               var vehicle_seats_owners: VehicleSeatsOwners&;
               vehicle_seats_components: VehicleSeatsComponents)
  var owners & = vehicle_seats_owners.data
  let seatOneOwnerEid = owners[seat1].eid
  let seatTwoOwnerEid = owners[seat2].eid
  let isPlayer = owners[seat1].isPlayer
  let eid = owners[seat1].eid
  let squad = owners[seat1].squad
  let player = owners[seat1].player
  owners[seat1].isPlayer = owners[seat2].isPlayer
  owners[seat1].eid = owners[seat2].eid
  owners[seat1].squad = owners[seat2].squad
  owners[seat1].player = owners[seat2].player
  owners[seat2].isPlayer = isPlayer
  owners[seat2].eid = eid
  owners[seat2].squad = squad
  owners[seat2].player = player
  let components & = vehicle_seats_components.data
  if seatOneOwnerEid != INVALID_ENTITY_ID
    set_vehicle_seat_component(seatOneOwnerEid, components[seat1], false)
    set_vehicle_seat_component(seatOneOwnerEid, components[seat2], true)
  if seatTwoOwnerEid != INVALID_ENTITY_ID
    set_vehicle_seat_component(seatTwoOwnerEid, components[seat2], false)
    set_vehicle_seat_component(seatTwoOwnerEid, components[seat1], true)

def change_seat(human_eid: EntityId;
                newSeatNo: int;
                var vehicle_seats_owners: VehicleSeatsOwners&;
                vehicle_seats_components: VehicleSeatsComponents)
  if !human_eid || newSeatNo < 0
    return
  let owners & = vehicle_seats_owners.data
  for seatNo in iter_range(owners)
    let oldSeatOwner & = owners[seatNo]
    if oldSeatOwner.eid == human_eid
      let newSeatOwner & = owners[newSeatNo]
      //someone could seat on this seat
      if !newSeatOwner.eid || !newSeatOwner.isPlayer
        swap_seats(seatNo, newSeatNo, vehicle_seats_owners, vehicle_seats_components)
      return

[es (tag=server)]
def vehicle_seats_swap(evt: CmdVehicleSwapSeats;
                       vehicle_seats_components: VehicleSeatsComponents;
                       var vehicle_seats_owners: VehicleSeatsOwners&)
  swap_seats(evt.seatNo1, evt.seatNo2, vehicle_seats_owners, vehicle_seats_components)

[es (tag=server, no_order)]
def vehicle_seats_switch_timer(info: UpdateStageInfoAct;
                               var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                               var vehicle_seats_owners: VehicleSeatsOwners&;
                               vehicle_seats_components: VehicleSeatsComponents)
  var times & = vehicle_seats_switch_time.data
  for index in iter_range(times)
    var switchTimeData & = times[index]
    if switchTimeData.time >= 0.
      switchTimeData.time -= info.dt
      if switchTimeData.time < 0.
        let owners & = vehicle_seats_owners.data
        let humanEid = owners[index].eid
        if humanEid != INVALID_ENTITY_ID
          change_seat(humanEid, switchTimeData.newSeatNo, vehicle_seats_owners, vehicle_seats_components)
        switchTimeData.time = -1.f
        switchTimeData.newSeatNo = -1

[es (tag=server)]
def vehicle_seats_switch_timer_enter(evt: EventEnterVehicle&;
                                     var vehicle_seats_switch_time: VehicleSeatsSwitchTime&;
                                     vehicle_seats_owners: VehicleSeatsOwners)
  if !evt.enter
    return
  let incomerIndex = get_seat_no(evt.incomer, vehicle_seats_owners)
  let owners & = vehicle_seats_owners.data
  let incomerSeat & = owners[incomerIndex]
  var times & = vehicle_seats_switch_time.data
  for index in iter_range(owners)
    var time & = times[index]
    if time.newSeatNo == incomerIndex
      time.newSeatNo = -1
      time.time = -1.f
      let awaitingChangeEid = owners[index].eid
      if incomerSeat.player == (get_Eid(awaitingChangeEid, "possessedByPlr") ?? INVALID_ENTITY_ID)
        let squadEid = get_Eid(awaitingChangeEid, "squad_member.squad") ?? INVALID_ENTITY_ID
        sendEvent(squadEid, [[RequestSquadChangeLeader eid=incomerSeat.eid]])
      return

[es]
def last_vehicle_tracker(evt: EventEnterVehicle;
                         var vehicle_dot_lastEid: EntityId&;
                         var vehicle_dot_lastTime: float&)
  vehicle_dot_lastEid = evt.vehicle
  vehicle_dot_lastTime = get_sync_time()
