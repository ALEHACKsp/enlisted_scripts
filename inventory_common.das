options remove_unused_symbols = false
module inventory_common
require ecs

def push_item_in_cont(owner_eid : EntityId; name : string; var itemContainer : EidList)
  let eid = createEntitySync(name) <| $ (var init: ComponentsInitializer)
    set(init, "item.ownerEid", owner_eid)
  push_back(itemContainer, eid)
