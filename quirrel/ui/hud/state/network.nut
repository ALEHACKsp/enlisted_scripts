local {CONNECTIVITY_OK} = require("connectivity")
/*
local netstats = {
  ping={dim=1, avg=1, min=0 max=1}
  rx={dim=1, avg=1, min=0 max=1}
  tx={dim=1, avg=1, min=0 max=1}
  rx_pps={dim=1, avg=1, min=0 max=1}
  tx_pps={dim=1, avg=1, min=0 max=1}
  ploss={dim=1, avg=1, min=0 max=1}
}
*/

local connectivity = persist("connectivity", @() Watched(CONNECTIVITY_OK))

::ecs.register_es("hud_network_ui_es", {
  [["onChange", "onInit"]] = function(evt, eid, comp) {
    connectivity(comp["hud_state.connectivity"])
  }
  onDestroy = @(eid, comp) connectivity(CONNECTIVITY_OK)
  },
  {
    comps_track = [["hud_state.connectivity", ::ecs.TYPE_INT]]
  }
)

return {
  connectivity
}
 