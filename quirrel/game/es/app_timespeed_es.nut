local {set_timespeed} = require("app")

::ecs.register_es("app_timespeed_es",
  {
    onChange = function (evt, eid, comp) {
      set_timespeed(comp["app.timeSpeed"])
    }

    onInit = function (evt, eid, comp) {
      set_timespeed(comp["app.timeSpeed"])
    }

    onDestroy = function (evt, eid, comp) {
      set_timespeed(1.0)
    }
  },
  { comps_track = [["app.timeSpeed", ::ecs.TYPE_FLOAT]]}
)

 