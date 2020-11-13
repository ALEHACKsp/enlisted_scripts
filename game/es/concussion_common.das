options remove_unused_symbols = false
module concussion_common
require ecs
require app
require ecs.common

def disable_concussion_affect(owner_eid : EntityId)
  find_query() <| $ [es (REQUIRE=concussionAffect)] (eid : EntityId; game_effect_dot_attachedTo : EntityId; var concussion_dot_replaced : bool&)
    if game_effect_dot_attachedTo != owner_eid
      return false
    concussion_dot_replaced = true
    destroyEntity(eid)
    return true

def enable_concussion_affect(owner_eid : EntityId; concussion_template : string)
  disable_concussion_affect(owner_eid)
  createEntity(concussion_template) <| $(var init : ComponentsInitializer)
    set(init, "game_effect.attachedTo", owner_eid)
    set(init, "concussion.startedAtTime", get_sync_time())

def has_concussion_affect(owner_eid : EntityId) : bool
  return find_query() <| $ [es (REQUIRE=concussionAffect)] (game_effect_dot_attachedTo : EntityId)
    return game_effect_dot_attachedTo == owner_eid