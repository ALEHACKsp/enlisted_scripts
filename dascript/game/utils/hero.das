options remove_unused_symbols = false
module hero
require ecs
require player

[generic]
def get_controlled_hero() : EntityId
  return get_Eid(get_local_player_eid(), "possessed") ?? INVALID_ENTITY_ID

[generic]
def get_watched_entity() : EntityId
  var watchedByPlr = INVALID_ENTITY_ID
  find_query() <| $[es (REQUIRE=watchedByPlr)] (eid : EntityId)
    watchedByPlr = eid
    return true
  return watchedByPlr
