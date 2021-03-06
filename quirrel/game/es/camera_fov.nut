local dgs_get_settings = require("dagor.system").dgs_get_settings

local function setFov(evt, eid, comp) {
  comp.fovSettings = clamp(dgs_get_settings()?.gameplay.camera_fov ?? comp.fovSettings, comp.fovLimits.x, comp.fovLimits.y)
}

::ecs.register_es("camera_fov_es", { onInit = setFov },
{ comps_rw = [ ["fovSettings", ::ecs.TYPE_FLOAT] ], comps_ro = [["fovLimits", ::ecs.TYPE_POINT2]] },
{tags = "gameClient"})

 