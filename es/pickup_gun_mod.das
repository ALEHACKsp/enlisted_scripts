require ecs
require ecs.common
require game.es.events
require inventory


[es (tag=server)]
def switch_gun_mod_es(evt : CmdInventorySwitchGunMod; eid : EntityId)
  let itemEid = evt.item
  query(eid) <| $ [es] (human_weap_dot_currentGunSlot : int; human_weap_dot_currentGunModEid : EntityId)
    query(itemEid) <| $ [es] (gunAttachable_dot_slotName : string)
      let toGround = !can_pickup_item_by_volume(human_weap_dot_currentGunModEid, eid)
      remove_item_from_weap_impl(eid, human_weap_dot_currentGunSlot, gunAttachable_dot_slotName, toGround)
      pickup_and_install_item_on_weap_impl(eid, itemEid, human_weap_dot_currentGunSlot, gunAttachable_dot_slotName)