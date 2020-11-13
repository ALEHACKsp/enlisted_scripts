require ecs

[es (tag=server, track=human_inventory_dot_entityToUse)]
def use_item_lock_stationary_gun_use(evt : Event;
                                     human_inventory_dot_entityToUse : EntityId;
                                     var human_use_object_dot_lockStationaryGunUseByHealing : bool&)
  human_use_object_dot_lockStationaryGunUseByHealing = human_inventory_dot_entityToUse != INVALID_ENTITY_ID
