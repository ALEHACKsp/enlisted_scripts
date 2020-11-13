require ecs
require EnlistedWalkerai
require enlisted.game.es.enlisted_events
require game.es.squad_common

[es(tag=server)]
def on_cancel_squad_mate_order(squadMateOrder:RequestSquadMateOrder; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId)
  if squadMateOrder.orderType == SquadMateOrder ESMO_NO_ORDER
    reset_squad_mate_orders(eid, squad_dot_leader)

[es(tag=server, track=squad_dot_leader)]
def reset_squad_mate_order_on_squad_leader_change(evt : Event; eid, squad_dot_leader : ecs::EntityId)
  reset_squad_mate_orders(eid, squad_dot_leader)

[es (tag=server, no_order)]
def sync_squad_mate_order_status(act : ecs::UpdateStageInfoAct; eid : ecs::EntityId; squad_dot_leader : ecs::EntityId;
                                squad_dot_numAliveMembers : int; var squad_dot_hasPersonalOrder : bool&)
  squad_dot_hasPersonalOrder = squad_dot_numAliveMembers > 1 && collect_squad(eid, squad_dot_leader) <| $(member_eid : EntityId)
    return get_int(member_eid, "squad_member.orderType") ?? int(SquadMateOrder ESMO_NO_ORDER) != int(SquadMateOrder ESMO_NO_ORDER)
