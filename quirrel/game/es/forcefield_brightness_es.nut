local {Point2, cvt} = require("dagor.math")
local {CmdUpdateForcefieldBrightness} = require("gameevents")

local setShaderVarsQuery = ::ecs.SqQuery("setShaderVarsQuery",
  {
    comps_rw = [["shader_vars.vars", ::ecs.TYPE_OBJECT]],
    comps_ro = [["forcefield_brightness.timeMap", ::ecs.TYPE_ARRAY]]
  }
)

local function setShaderVars(curTime){
  setShaderVarsQuery.perform(function(eid, comp){
    local firstTimeMarker = Point2(0, 8)
    foreach (time in comp["forcefield_brightness.timeMap"]) {
      if (curTime <= time.x) {
        local val = cvt(curTime, firstTimeMarker.x, time.x, firstTimeMarker.y, time.y)
        comp["shader_vars.vars"].forcefield_brightness = val
        break
      }
      firstTimeMarker = time
    }
  })
}

::ecs.register_es("forcefield_brightness_update_es", {
    [CmdUpdateForcefieldBrightness] = function(evt, eid, comp) { setShaderVars(evt[0]) }
  }
)

::ecs.register_es("forcefield_brightness_es_init_day", {
    function onInit(eid, comp) {
      setShaderVars(comp["level.timeOfDay"])
    },
  },
  {
    comps_ro = [["level.timeOfDay", ::ecs.TYPE_FLOAT]]
  }
)
 