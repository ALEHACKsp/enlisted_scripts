local findGroupQuery = ::ecs.SqQuery("findGroupQuery", {comps_ro = [["groupName", ::ecs.TYPE_STRING]]})

local function activateGroup(group_name) {
  local function sendEvent(eid, comp) {
    if (comp.groupName == group_name)
     ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityActivate({activate=true}))
  }

  findGroupQuery.perform(sendEvent)
}

return activateGroup

 