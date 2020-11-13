require ecs

[es (on_event=(EventEntityCreated, EventComponentsAppear), REQUIRE=locked_inventory_dot_lockPickup)]
def locked_looting_set_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var locked_dot_pickupItemsLockedByAffect : bool&)
    locked_dot_pickupItemsLockedByAffect = true

[es (on_event=EventEntityDestroyed, REQUIRE=locked_inventory_dot_lockPickup)]
def locked_looting_unset_es(evt:Event; game_effect_dot_attachedTo : EntityId)
  ecs::query(game_effect_dot_attachedTo) <| $ [es] (var locked_dot_pickupItemsLockedByAffect : bool&)
    locked_dot_pickupItemsLockedByAffect = false
