local function updateAFK(dt, eid, comp) {
  local afkTime = comp["afk.time"].tointeger()
  if (afkTime == comp["afk.showWarningTimeout"])
    ::ecs.server_send_net_sqevent(eid, ::ecs.event.AFKShowWarning(), [comp.connid])
  if (afkTime == comp["afk.showDisconnectWarningTimeout"])
    ::ecs.server_send_net_sqevent(eid, ::ecs.event.AFKShowDisconnectWarning(), [comp.connid])
}

::ecs.register_es("afk_server_es",
  { onUpdate = updateAFK },
  { comps_ro=[["connid", ::ecs.TYPE_INT], ["afk.time", ::ecs.TYPE_FLOAT], ["afk.showWarningTimeout", ::ecs.TYPE_INT], ["afk.showDisconnectWarningTimeout", ::ecs.TYPE_INT]] },
  { tags="server", updateInterval = 1.0, after="*", before="*" }) 