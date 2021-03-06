local {mkCountdownTimerPerSec} = require("ui/helpers/timers.nut")

local requestAmmoAllowTime = ::Watched(0.0)
local requestAmmoTimeout = mkCountdownTimerPerSec(requestAmmoAllowTime)

::ecs.register_es("hero_ammo_request_ui_es",
  {
    [["onInit", "onChange"]] = @(evt, eid, comp) requestAmmoAllowTime(comp["requestAmmoAllowTime"])
  },
  { comps_track = [["requestAmmoAllowTime", ::ecs.TYPE_FLOAT]] }
)

return {
  requestAmmoTimeout = requestAmmoTimeout
} 