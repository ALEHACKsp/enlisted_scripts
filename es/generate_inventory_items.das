require ecs
require game.es.inventory_common

[es (on_event=(EventEntityCreated, EventComponentsAppear), tag=server)]
def generate_initial_inventory_items_es(evt:Event; eid : EntityId; var inventory_items_dot_initialInventory : ecs::Array;
                                        var itemContainer : EidList)
  for it in inventory_items_dot_initialInventory
    let name = string(deref(get_ecs_string(it)))
    push_item_in_cont(eid, name, itemContainer)
  clear(inventory_items_dot_initialInventory)

[es (on_event=EventOnMovingZoneDone, tag=server)]
def generate_items_in_first_zone_es(evt:Event; eid : EntityId; isAlive:bool;
  var inventory_items_dot_generateInFirstZone : ecs::Array; var itemContainer : EidList)
  if !isAlive
    return
  for it in inventory_items_dot_generateInFirstZone
    let name = string(deref(get_ecs_string(it)))
    push_item_in_cont(eid, name, itemContainer)
  clear(inventory_items_dot_generateInFirstZone)
