require ecs

[es (tag=server, track=burning_dot_isBurning)]
def burning_affect(evt : Event; eid : EntityId; burning_dot_isBurning : bool)
  let ownerEid& = eid

  var alreadyApplied = find_query() <| $ [es (REQUIRE=burning_affect)] (eid : EntityId; game_effect_dot_attachedTo : EntityId)
    if game_effect_dot_attachedTo != ownerEid
      return false
    if !burning_dot_isBurning
      destroyEntity(eid)
    return true

  if !alreadyApplied && burning_dot_isBurning
    createEntity("burning_affect") <| $(var init : ComponentsInitializer)
      set(init, "game_effect.attachedTo", ownerEid)
