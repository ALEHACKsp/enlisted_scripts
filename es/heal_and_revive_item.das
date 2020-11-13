require ecs
require game.es.events

[es (tag=server)]
def heal_and_revive_item_state(evt : EventOnItemStartUse;
                               var item_dot_isCurrentlyUsedForReviveTarget : bool&)
  query(evt.target) <| $[es] (isDowned : bool)
    item_dot_isCurrentlyUsedForReviveTarget = isDowned