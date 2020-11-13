require ecs
require game.es.events
require game.utils.hero

[es (tag=gameClient)]
def track_updated_hero_items_es(evt:EventHeroChanged; var itemContainer : EidList)
  for eid in itemContainer
    ecs::query(eid) <| $ [es] (item_dot_ownerEid : ecs::EntityId)
      if evt.eid != ecs::INVALID_ENTITY_ID && item_dot_ownerEid == evt.eid
        addSubTemplate(eid, "controllable_hero_item")
      else
        removeSubTemplate(eid, "controllable_hero_item")

[es (on_event=EventEntityDied, tag=gameClient)]
def track_died_hero_items_es(evt:Event; eid : EntityId; var itemContainer : EidList)
  if eid != get_controlled_hero()
    return
  for itemEid in itemContainer
    if has(itemEid, "item.owned_controllable_hero")
      removeSubTemplate(itemEid, "controllable_hero_item")

[es (on_event=(EventEntityCreated, EventComponentsAppear), on_event=EventComponentChanged, track=item_dot_ownerEid, tag=gameClient)]
def controlable_hero_items_es(evt:Event; eid : ecs::EntityId; item_dot_ownerEid : ecs::EntityId)
  if item_dot_ownerEid != INVALID_ENTITY_ID && item_dot_ownerEid == get_controlled_hero()
    addSubTemplate(eid, "controllable_hero_item")
  elif has(eid, "item.owned_controllable_hero")
    removeSubTemplate(eid, "controllable_hero_item")
