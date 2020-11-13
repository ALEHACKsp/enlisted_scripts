options remove_unused_symbols = false
module artillery_radio_common
require ecs
require app
require HumanPhys

def get_radio_eid(human_weap_dot_gunEids : EidList const)
  let weapEid = human_weap_dot_gunEids[int(HUWeaponSlots EWS_SECONDARY)]
  return has(weapEid, "radio_use") ? weapEid : INVALID_ENTITY_ID

def has_radio(human_weap_dot_gunEids : EidList const)
  return get_radio_eid(human_weap_dot_gunEids) != INVALID_ENTITY_ID

def has_radioman_squadmate_for_order(squad_eid : EntityId; leader_eid: EntityId)
  return find_query() <| $ [es] (eid : ecs::EntityId;
                                 squad_member_dot_squad : ecs::EntityId;
                                 human_weap_dot_gunEids : ecs::EidList;
                                 isAlive : bool;
                                 isDowned : bool = false)
    return squad_eid == squad_member_dot_squad && eid != leader_eid && isAlive && !isDowned && has_radio(human_weap_dot_gunEids)

def is_artillery_on_cooldown(playerEid : EntityId)
  return get_sync_time() < get_float(playerEid, "artillery.availableAtTime") ?? 0.0

def can_order_artillery_strike(eid, squad_eid : EntityId)
  var res = false
  query(eid) <| $ [es] (isAlive : bool; isDowned : bool; possessedByPlr : EntityId)
    res = isAlive && !isDowned && has_radioman_squadmate_for_order(squad_eid, eid) && !is_artillery_on_cooldown(possessedByPlr)
  return res
