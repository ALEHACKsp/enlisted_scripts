local Point3 = require("dagor.math").Point3

local forestallMarkActive = persist("forestallMarkActive", @() ::Watched(false))
local forestallMarkPos = persist("forestallMarkPos", @() ::Watched(Point3(0, 0, 0)))
local forestallMarkOpacity = persist("forestallMarkOpacity", @() ::Watched(1.0))

local function updateForestallPos(evt, eid, comp) {
  forestallMarkActive.update(comp["target_lock.selectedEntity"] != INVALID_ENTITY_ID)
  forestallMarkPos.update(comp["forestallPos"])
  forestallMarkOpacity.update(comp["forestallOpacity"])
}

local function hideForestallMark(evt, eid, comp) {
  forestallMarkActive.update(false)
}

::ecs.register_es("forestall_mark_ui_es", {
    [["onInit", "onChange"]] = updateForestallPos,
    [::ecs.EventComponentsDisappear] = hideForestallMark,
  },
  { comps_track = [
      ["forestallPos", ::ecs.TYPE_POINT3],
      ["forestallOpacity", ::ecs.TYPE_FLOAT],
      ["target_lock.selectedEntity", ::ecs.TYPE_EID]
    ],
    comps_rq = ["heroVehicle"]
  },
  { tags="gameClient"}
)

return {
  forestallMarkActive = forestallMarkActive
  forestallMarkPos = forestallMarkPos
  forestallMarkOpacity = forestallMarkOpacity
}
 