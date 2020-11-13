require ecs

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server)]
def drop_item_es(evt:Event; var transform:float3x4; dropTm:float3x4)
  transform = transform * dropTm

