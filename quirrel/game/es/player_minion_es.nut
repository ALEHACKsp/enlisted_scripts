local function onInit(evt, eid, comp) {
  if (comp["player_minion.minion"] != INVALID_ENTITY_ID || comp["player_minion.loading"])
    return

  local comps = {
    "minion.attachedTo" : [eid, ::ecs.TYPE_EID],
  }
  comp["player_minion.loading"] = true
  ::ecs.g_entity_mgr.createEntity(comp["player_minion.type"], comps,
      function(eid) {
        local myEid = ::ecs.get_comp_val(eid, "minion.attachedTo", INVALID_ENTITY_ID)
        if (!::ecs.g_entity_mgr.doesEntityExist(myEid)) {
          ::ecs.g_entity_mgr.destroyEntity(eid)
          return
        }
        ::ecs.set_comp_val(myEid, "player_minion.minion", eid)
      })
}

local function onHolderDestroy(evt, eid, comp) {
  if (comp["player_minion.minion"] != INVALID_ENTITY_ID)
    ::ecs.g_entity_mgr.destroyEntity(comp["player_minion.minion"])
}

local comps = {
  comps_ro = [["player_minion.type", ::ecs.TYPE_STRING]]
  comps_rw = [["player_minion.minion", ::ecs.TYPE_EID], ["player_minion.loading", ::ecs.TYPE_BOOL]],
}

::ecs.register_es("player_minion_es", {
  onInit = onInit,
  onDestroy = onHolderDestroy,
}, comps, {tags = "render"})
 