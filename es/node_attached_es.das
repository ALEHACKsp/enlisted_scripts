require ecs
require game.es.events
require AnimV20

[es (tag=render, no_order)]
def node_attached_itm(info : UpdateStageInfoAct;
    node_attached_dot_entity : EntityId;
    node_attached_dot_nodeId : int;
    node_attached_dot_localTm : float3x4;
    var transform : float3x4&)
  if node_attached_dot_nodeId < 0
    return

  query(node_attached_dot_entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    animchar_get_node_wtm(animchar, node_attached_dot_nodeId, tm)
    transform = tm * node_attached_dot_localTm

[es (tag=render, no_order)]
def node_attached_pos(info : UpdateStageInfoAct;
    node_attached_dot_entity : EntityId;
    node_attached_dot_nodeId : int;
    node_attached_dot_localPos : float3;
    var transform : float3x4&)
  if node_attached_dot_nodeId < 0
    return

  query(node_attached_dot_entity) <| $ [es] (animchar : AnimcharBaseComponent)
    var tm : float3x4
    animchar_get_node_wtm(animchar, node_attached_dot_nodeId, tm)
    transform[3] = tm * node_attached_dot_localPos

[es (tag=server, no_order, REQUIRE=(node_attached_dot_destroyWithParent, replication))]
def node_attached_destroy_with_parent_replicating(info : UpdateStageInfoAct;
    eid : EntityId;
    node_attached_dot_entity : EntityId)
  if !doesEntityExist(node_attached_dot_entity)
    destroyEntity(eid)

[es (no_order, REQUIRE=node_attached_dot_destroyWithParent, REQUIRE_NOT=replication)]
def node_attached_destroy_with_parent_nonreplicating(info : UpdateStageInfoAct;
    eid : EntityId;
    node_attached_dot_entity : EntityId)
  if !doesEntityExist(node_attached_dot_entity)
    destroyEntity(eid)
