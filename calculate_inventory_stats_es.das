require ecs

def calculate_current_volume_impl(itemContainer : EidList;
                                  human_equipment_dot_slots : ecs::Object;
                                  human_weap_dot_gunEids : ecs::EidList;
                                  human_weap_dot_gunMods : ecs::EidList;
                                  var human_inventory_dot_currentVolume : float&;
                                  var human_inventory_dot_currentWeight : float&)
  human_inventory_dot_currentVolume = 0.0
  human_inventory_dot_currentWeight = 0.0

  for itemEid in itemContainer
    if !itemEid
      continue
    let volume = get_float(itemEid, "item.volume") ?? 0.
    let weight = get_float(itemEid, "item.weight") ?? 0.
    human_inventory_dot_currentVolume += volume
    human_inventory_dot_currentWeight += weight

  for it in human_equipment_dot_slots
    var obj = get_ecs_object(it.value)
    if obj == null
      continue
    let itemEid = get_Eid(obj, "item") ?? INVALID_ENTITY_ID
    if !itemEid
      continue
    query(itemEid) <| $ [es] (item_dot_weight : float)
      human_inventory_dot_currentWeight += item_dot_weight

  for it in human_weap_dot_gunEids
    query(it) <| $ [es] (item_dot_weight : float)
      human_inventory_dot_currentWeight += item_dot_weight
    let ammoHolderEid = get_Eid(it, "gun.ammoHolderEid") ?? INVALID_ENTITY_ID
    if ammoHolderEid != INVALID_ENTITY_ID
      query(ammoHolderEid) <| $ [es] (item_dot_weight : float)
        human_inventory_dot_currentWeight += item_dot_weight

  for it in human_weap_dot_gunMods
    query(it) <| $ [es] (item_dot_weight : float)
      human_inventory_dot_currentWeight += item_dot_weight

[es (tag=server,
      on_event=(EventEntityCreated, EventComponentsAppear),
      track=itemContainer,
      track=human_equipment_dot_slots,
      track=human_weap_dot_gunEids,
      track=human_weap_dot_gunMods,
      on_event=EventScriptReloaded)]
def calculate_current_volume_es(evt:Event;
                                itemContainer : EidList;
                                human_equipment_dot_slots : ecs::Object;
                                human_weap_dot_gunEids : ecs::EidList;
                                human_weap_dot_gunMods : ecs::EidList;
                                var human_inventory_dot_currentVolume : float&;
                                var human_inventory_dot_currentWeight : float&)
  calculate_current_volume_impl(itemContainer, human_equipment_dot_slots,
    human_weap_dot_gunEids, human_weap_dot_gunMods,
    human_inventory_dot_currentVolume, human_inventory_dot_currentWeight)

[es (tag=server,
      on_event=(EventEntityCreated, EventComponentsAppear),
      track=gun_dot_ammoHolderEid,
      REQUIRE=gun_dot_ammoHolderEid)]
def calculate_current_volume_for_gun_es(evt:Event;
                                        gun_dot_owner : ecs::EntityId)
  query(gun_dot_owner) <| $[es] (itemContainer : EidList;
                                 human_equipment_dot_slots : ecs::Object;
                                 human_weap_dot_gunEids : ecs::EidList;
                                 human_weap_dot_gunMods : ecs::EidList;
                                 var human_inventory_dot_currentVolume : float&;
                                 var human_inventory_dot_currentWeight : float&)
    calculate_current_volume_impl(itemContainer, human_equipment_dot_slots,
      human_weap_dot_gunEids, human_weap_dot_gunMods,
      human_inventory_dot_currentVolume, human_inventory_dot_currentWeight)
