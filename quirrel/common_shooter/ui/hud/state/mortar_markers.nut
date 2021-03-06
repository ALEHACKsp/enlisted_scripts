local mortarMarkers = Watched([])

local mortarMarkersQuery = ::ecs.SqQuery("mortarMarkersQuery", { comps_rq = ["mortar_marker"], comps_ro=[["transform", ::ecs.TYPE_MATRIX], ["type", ::ecs.TYPE_STRING]]})
local function updateMarkers(ignore=INVALID_ENTITY_ID) {
  local markers = []
  mortarMarkersQuery.perform(function(eid, comp) {
    if (eid != ignore)
      markers.append({pos=comp.transform.getcol(3), type=comp.type})
  })
  mortarMarkers(markers)
}

::ecs.register_es("mortar_marker_ui_es",
  { onInit = @(evt,eid,comp) updateMarkers()
    onDestroy = @(evt,eid,comp) updateMarkers(eid)
  },
  { comps_rq = ["mortar_marker"] },
  { tags = "gameClient" }
)

return mortarMarkers 