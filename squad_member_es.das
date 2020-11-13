require ecs
require EnlistedWalkerai
require game.es.ai.walker_common
require HumanPhys
require CollRes
require DagorMath
require DagorMathUtils
require DagorDebug3D
require AnimV20
require EnlistedHuman
require GridCollision
require DagorDataBlock
require DagorRandom
require soundHash
require vehicle
require game.es.sound.sound_events
require game.es.squad_common
require game.es.vehicle.vehicle_seats_common

def is_timer_hit(var timer : float&; dt : float) : bool
  if (timer > 0.f)
    timer -= dt
    return timer <= 0.f ? true : false
  return false

[es(no_order)]
def squad_member_es(info : ecs::UpdateStageInfoAct;
             eid : ecs::EntityId;
             var squad_member_dot_responseTimer : float&;
             squad_member_dot_response : string;
             squad_member_dot_squad : ecs::EntityId;
             isAlive : bool)
  if !isAlive || squad_member_dot_squad == ecs::INVALID_ENTITY_ID
    return
  var leaderEid = get_Eid(squad_member_dot_squad, "squad.leader") ?? INVALID_ENTITY_ID

  if (eid == leaderEid)
    return
  let isResponseRequired = is_timer_hit(squad_member_dot_responseTimer, info.dt)
  if isResponseRequired
    sendEvent(eid, [[CmdRequestHumanSpeech phrase=sound_hash(squad_member_dot_response + "Response"), threshold=1.]])


[es(no_order, tag=server)]
def squad_member_avoid_leader(info : UpdateStageInfoAct; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId;
                              var squad_dot_nextOverlapMembersUpdate : float;
                              squad_dot_overlapMembersUpdate:float = 0.7; squad_dot_overlapMembersDistance : float = 15.;
                              squad_dot_stanceChangeOrderTime:float2 = float2(4f, 7f))
  if squad_dot_nextOverlapMembersUpdate > info.curTime
    return
  squad_dot_nextOverlapMembersUpdate = info.curTime + squad_dot_overlapMembersUpdate
  let aimTmRef = get_TMatrix(squad_dot_leader, "human.aimTm")
  if aimTmRef == null
    return
  let aimTm = *aimTmRef
  let dist = squad_dot_overlapMembersDistance
  let rayEnd = aimTm[3] + aimTm[0] * squad_dot_overlapMembersDistance
  for_each_object_in_grid(GridType GT_DEFAULT, BBox3(aimTm[3] + aimTm[0] * dist * 0.5, dist)) <| $(it:TraceableGridCollision#)
    query(it.eid) <| $ [es] (squad_member_dot_squad : EntityId; transform : float3x4; human_net_phys : HumanActor;
                            collres: CollisionResource; animchar: AnimcharBaseComponent; var walker_agent : EntityAgent)
      if squad_member_dot_squad != eid || human_net_phys.phys.currentState.moveState != HUMoveState EMS_STAND
        return
      var t = squad_dot_overlapMembersDistance
      var norm : float3
      if !collres_traceray(collres, transform, animchar, aimTm[3], aimTm[0], t, norm)
        return
      let stance = determinate_stance(human_net_phys.phys.currentState)
      if stance > STANCE_CRAWL
        walker_agent.blackBoard |> datablock_setInt("maxStanceOrder", stance - 1)
        let orderTime = rnd_float(squad_dot_stanceChangeOrderTime.x, squad_dot_stanceChangeOrderTime.y)
        walker_agent.blackBoard |> datablock_setReal("maxStanceOrderEndTime", info.curTime + orderTime)

[es (tag=server, on_event=EventComponentChanged, track=isInVehicle)]
def squad_member_can_be_leader_set(evt: Event; isInVehicle: bool; var squad_member_dot_canBeLeader : bool&)
  if (!isInVehicle)
    // Not in vehicle anymore, can be leader
    squad_member_dot_canBeLeader = true

[es (tag=server, on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventComponentChanged, track=vehicle_seats_owners)]
def squad_member_can_be_leader_update(evt: Event; vehicle_seats_owners: VehicleSeatsOwners; vehicle_seats_order: VehicleSeatsOrder)
  let owners & = vehicle_seats_owners.data
  let orders & = vehicle_seats_order.data
  for seatNo in iter_range(owners)
    setOptional(owners[seatNo].eid, "squad_member.canBeLeader", can_place_manually(seatNo, orders))
