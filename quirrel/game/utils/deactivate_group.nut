local deactivateGroupQuery = ::ecs.SqQuery("deactivateGroupQuery", {comps_ro = [["groupName", ::ecs.TYPE_STRING]]})

local function deactivateGroup(group_name){
  local function sendEvent(eid, comp) {
    if (comp.groupName == group_name)
      ::ecs.g_entity_mgr.sendEvent(eid, ::ecs.event.EventEntityActivate({activate=false}))
  }
  deactivateGroupQuery.perform(sendEvent)
}

return deactivateGroup

 