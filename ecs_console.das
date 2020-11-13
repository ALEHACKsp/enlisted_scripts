require ecs
require DagorConsole

[console_cmd(name="ecs.create_entity", hint="ecs.create_entity (template_name)")]
def ecs_console_create_entity(template_name : string)
  query() <| $ [es](camera_dot_active: bool; transform: float3x4)
    if !camera_dot_active
      return
    createEntity(template_name) <| $ (var init: ComponentsInitializer)
      set(init, "transform", transform)

