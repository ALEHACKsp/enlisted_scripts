local {playerEvents} = require("ui/hud/state/eventlog.nut")
local {CmdShowVehicleDamageEffectsHint} = require("vehicle")
local {DM_EFFECT_FIRE} = require("dm")

::ecs.register_es("ui_vehicle_on_fire_hp_es", {
  [CmdShowVehicleDamageEffectsHint] = function(evt, eid, comp) {
    local effects = evt[2]
    if ((effects & (1 << DM_EFFECT_FIRE)) != 0)
      playerEvents.pushEvent({name = "PlayerVehicleOnFire", text = ::loc("PlayerVehicleOnFire"), ttl = 10}, ["name"])
  }
},
{comps_rq=["hero"]})

 