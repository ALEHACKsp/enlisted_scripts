require ecs

[es (on_event=EventEntityDied, on_event=(EventEnterVehicle, EventEntityDowned, EventInterruptItemUse, EventEntityRevived))]
def interrupt_item_use_es(evt:Event;
                                        var human_inventory_dot_entityUseEnd : float&;
                                        var human_inventory_dot_entityUseStart : float&;
                                        var human_inventory_dot_entityToUse : ecs::EntityId&;
                                        var human_inventory_dot_targetToUse : ecs::EntityId&;
                                        var human_inventory_dot_savedUseProgress : float&;
                                        var human_inventory_dot_usePausedUntilTime : float&)
  if human_inventory_dot_targetToUse != INVALID_ENTITY_ID
    query(human_inventory_dot_targetToUse) <| $ [es] (var hitpoints_dot_countRevivers : int&)
      if hitpoints_dot_countRevivers > 0
        hitpoints_dot_countRevivers--
  human_inventory_dot_entityUseEnd = -1.0
  human_inventory_dot_entityUseStart = -1.0
  human_inventory_dot_entityToUse = INVALID_ENTITY_ID
  human_inventory_dot_targetToUse = INVALID_ENTITY_ID
  human_inventory_dot_savedUseProgress = -1.0
  human_inventory_dot_usePausedUntilTime = -1.0
