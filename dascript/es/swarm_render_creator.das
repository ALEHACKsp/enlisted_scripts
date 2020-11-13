require ecs

[es (tag=render, on_event=(EventEntityCreated, EventComponentsAppear))]
def swarm_render_creator(evt: Event; var swarmRenderEntity : EntityId&;
                        swarmRenderTemplate: string; var isSwarmRenderCreating: bool&)
  let curSwarmRenderTemplate = swarmRenderTemplate
  var renderEntity & = swarmRenderEntity
  var alreadyCreating = find_query() <| $ [es](swarmRenderEntity : EntityId; swarmRenderTemplate: string; isSwarmRenderCreating: bool)
    if curSwarmRenderTemplate == swarmRenderTemplate && isSwarmRenderCreating
      renderEntity = swarmRenderEntity
      return true
    return false
  if alreadyCreating
    return
  find_query() <| $[es](globalSwarmRenders : Object)
    alreadyCreating = globalSwarmRenders |> has(swarmRenderTemplate)
    return true
  if alreadyCreating
    return
  swarmRenderEntity = createEntity(swarmRenderTemplate)
  isSwarmRenderCreating = true
  find_query() <| $[es](var globalSwarmRenders : Object&)
    globalSwarmRenders |> set(swarmRenderTemplate, swarmRenderEntity)
    return true
