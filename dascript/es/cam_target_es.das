require ecs

[es (on_event=(EventEntityCreated, EventComponentsAppear), track=camera_dot_target)]
def cam_target_switcher_es(evt:Event; camera_dot_target : ecs::EntityId; var camera_dot_prevTarget : ecs::EntityId&)
  setOptional(camera_dot_prevTarget, "isCameraTarget", false)
  setOptional(camera_dot_target, "isCameraTarget", true)
  camera_dot_prevTarget = camera_dot_target

