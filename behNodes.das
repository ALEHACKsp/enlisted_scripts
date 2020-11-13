require ecs
require BehNodes

[generic]
def beh_tree_eid(tree : BehaviourTree?)
  return tree != null ? beh_tree_eid(*tree) : INVALID_ENTITY_ID

[generic]
def beh_tree_eid(tree : BehaviourTree)
  return EntityId(uint(tree.id))

[generic]
def beh_tree_current_name(tree : BehaviourTree; full = false)
  return __builtin_beh_tree_current_name(tree, full)

[generic]
def beh_tree_current_name(tree : BehaviourTree?; full = false)
  return tree != null ? __builtin_beh_tree_current_name(*tree, full) : ""

[generic]
def beh_node_current_name(node : BehNode; full = false; children = true)
  return __builtin_beh_node_current_name(node, full, children)

[generic]
def beh_node_current_name(node : BehNode?; full = false; children = true)
  return node != null ? __builtin_beh_node_current_name(*node, full, children) : ""

[generic]
def beh_node_hierarchy_name(node : BehNode; full = false)
  return __builtin_beh_node_hierarchy_name(node, full)

[generic]
def beh_node_hierarchy_name(node : BehNode?; full = false)
  return node != null ? __builtin_beh_node_hierarchy_name(*node, full) : ""
