local state = persist("vehicleRespawnBases", @() Watched({eids=[] byType={}}))

local function track(evt, eid, comp) {
  local active = comp.active
  local respawnbaseType = comp.respawnbaseType

  state(function (st) {
    if (active)
      st.eids.append([eid, respawnbaseType])
    else
      st.eids = st.eids.filter(@(v) v[0] != eid)

    st.byType = {}
    foreach (v in st.eids) {
      local respEid = v[0];
      local respType = v[1];
      if (respType in st.byType)
        st.byType[respType].append(respEid)
      else
        st.byType[respType] <- [respEid]
    }
  })
}

::ecs.register_es("vehicle_respawn_bases_ui_es",
  {[["onInit", "onChange"]] = track},
  {
    comps_track=[["active", ::ecs.TYPE_BOOL]]
    comps_ro = [["respawnbaseType", ::ecs.TYPE_STRING, ""]]
    comps_rq = ["vehicleRespbase"]
  })

return state 