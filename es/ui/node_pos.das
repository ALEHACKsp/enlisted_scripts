require ecs
require DagorSystem
require AnimV20

[es (tag=ui, after=animchar_es)]
def ui_geom_node_pos(info: UpdateStageInfoAct;
                       ui_dot_geom_node_idx:int;
                       animchar : AnimcharBaseComponent;
                       var ui_dot_node_pos:float3&)
  if ui_dot_geom_node_idx>=0
    ui_dot_node_pos = animchar_get_node_wpos(animchar, ui_dot_geom_node_idx)

[es (tag=ui, on_event=(EventComponentsAppear, EventEntityCreated), track=ui_dot_geom_node_name)]
def ui_geom_node_pos_name(evt : Event;
                          eid:EntityId;
                          animchar : AnimcharBaseComponent;
                          ui_dot_geom_node_name:string;
                          var ui_dot_geom_node_idx :int&)
  ui_dot_geom_node_idx = animchar_find_node_index(animchar, ui_dot_geom_node_name)
  if ui_dot_geom_node_idx < 0
    logerr("Node {ui_dot_geom_node_name} not found in animchar for eid {eid} {getEntityTemplateName(eid)}")

