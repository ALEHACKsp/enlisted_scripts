local { sound_set_fixed_time_speed } = require("sound")

::ecs.register_es("sound_control_es",
  {
    function onChange(evt, eid, comp) {
      sound_set_fixed_time_speed(comp["sound_control.fixedTimeSpeed"])
    }

    function onInit(evt, eid, comp) {
      sound_set_fixed_time_speed(comp["sound_control.fixedTimeSpeed"])
    }

    function onDestroy (evt, eid, comp) {
      sound_set_fixed_time_speed(0.0)
    }
  },
  { comps_track = [["sound_control.fixedTimeSpeed", ::ecs.TYPE_FLOAT]]}
)
 