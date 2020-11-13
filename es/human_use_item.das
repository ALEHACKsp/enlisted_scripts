require ecs
require inventory
require game.es.events
require math

[es]
def human_inventory_medkit_cancel_es(evt: CmdMedkitUseCancel; eid : ecs::EntityId)
  sendEventImmediate(eid, [[CmdPutOutFireStop]])
  inventory::stop_use_item(eid)


def get_fastest_heal_item(item_container : EidList; heal_amount_comp : string)
  var fastestTime = 1e+06f
  var fastestEid = ecs::INVALID_ENTITY_ID

  for itemEid in item_container
    let useTime = get_float(itemEid, "item.useTime") ?? fastestTime
    if has(itemEid, heal_amount_comp) && useTime < fastestTime
      fastestTime = useTime
      fastestEid = itemEid
  return fastestEid


[es]
def human_inventory_medkit_es(evt: CmdMedkitUse; eid : ecs::EntityId;
                              itemContainer : EidList;
                              hitpoints_dot_hp : float;
                              hitpoints_dot_maxHp : float;
                              isAlive : bool;
                              burning_dot_isBurning : bool = false;
                              human_medkit_dot_allowUseOnFullHP : bool = false;
                              isDowned : bool = false)
  if burning_dot_isBurning
    sendEventImmediate(eid, [[CmdPutOutFireStart]])
    return
  let needHp = hitpoints_dot_maxHp - max(hitpoints_dot_hp, 0.f)
  if !isAlive || (!human_medkit_dot_allowUseOnFullHP && needHp < 1e-06f)
    return

  let healAmountComp = isDowned ? "item.reviveAmount" : "item.healAmount"
  let bestItem = get_fastest_heal_item(itemContainer, healAmountComp)
  if bestItem != ecs::INVALID_ENTITY_ID
    inventory::use_item(eid, bestItem, ecs::INVALID_ENTITY_ID)

