options remove_unused_symbols = false
module node_attach
require ecs
require AnimV20


def attach_to_node(eid : EntityId; bind_to_eid : EntityId; node_id : int; local_tm : float3x4)
  addSubTemplate(eid, "node_attached_itm") <| $(var init)
    set(init, "node_attached.entity", bind_to_eid)
    set(init, "node_attached.nodeId", node_id)
    set(init, "node_attached.localTm", local_tm)

def attach_to_node(eid : EntityId; bind_to_eid : EntityId; node_id : int)
  var tm : float3x4
  identity(tm)
  attach_to_node(eid, bind_to_eid, node_id, tm)

def attach_to_node_pos(eid : EntityId; bind_to_eid : EntityId; node_id : int; local_pos : float3)
  addSubTemplate(eid, "node_attached_pos") <| $(var init)
    set(init, "node_attached.entity", bind_to_eid)
    set(init, "node_attached.nodeId", node_id)
    set(init, "node_attached.localPos", local_pos)

def get_node_local_pos(eid : EntityId; node_id : int; var pos : float3&) : bool
  var queryStatus = false
  query(eid) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    animchar_get_node_wtm(animchar, node_id, tm)
    pos = inverse(tm) * pos;
    queryStatus = true
  return queryStatus