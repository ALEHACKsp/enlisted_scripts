require ecs
require inventory
require math
require math.base
require game.es.events

[es (tag=gameClient, REQUIRE=hero, no_order)]
def automatic_pickup_items_es(info : ecs::UpdateStageInfoAct;
                              eid:EntityId; transform : float3x4;
                              var auto_pickup_dot_lastTime : float&;
                              auto_pickup_dot_delta : float;
                              human_dot_canPickupItems, isAlive, isDowned : bool)
  let canPickup = human_dot_canPickupItems && isAlive && !isDowned
  if !canPickup || info.curTime - auto_pickup_dot_lastTime < auto_pickup_dot_delta
    return
  auto_pickup_dot_lastTime = info.curTime
  let heroPos = transform[3]
  let hero = eid
  ecs::find_query() <| $[es (REQUIRE=traceVisibility)](eid, item_dot_lastOwner : EntityId; transform : float3x4; item_dot_automaticPickupRange : float)
    if item_dot_lastOwner != hero && inventory::is_item_useful(hero, eid) && square(item_dot_automaticPickupRange) > length_sq(transform[3] - heroPos)
      inventory::pickup_item(hero, eid)
      return true
    return false

[es (tag=gameClient, REQUIRE=hero)]
def pickup_common_items_es(evt:CmdInventoryPickup; eid:EntityId; transform:float3x4)
  let hero = eid
  let heroPos = transform[3]
  ecs::query(evt.itemEid) <| $ [es (REQUIRE=item_dot_commonPickupRange)] (eid:EntityId; item_dot_id : int)
    let firstItemId = item_dot_id
    let firstItemEid = eid
    ecs::query() <| $ [es (REQUIRE=traceVisibility)] (item_dot_commonPickupRange: float; eid : EntityId; item_dot_id : int; transform:float3x4)
      if firstItemEid != eid && firstItemId == item_dot_id && square(item_dot_commonPickupRange) > length_sq(transform[3] - heroPos)
        inventory::pickup_item(hero, eid)

