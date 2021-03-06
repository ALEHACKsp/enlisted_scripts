local {Point2} = require("dagor.math")
local {inPlane} = require("ui/hud/state/vehicle_state.nut")

local mmapComps = {comps_ro = [
  ["left_top", ::ecs.TYPE_POINT2],
  ["right_bottom", ::ecs.TYPE_POINT2],
  ["farLeftTop", ::ecs.TYPE_POINT2, Point2(0,0)],
  ["farRightBottom", ::ecs.TYPE_POINT2, Point2(0,0)],
  ["northAngle", ::ecs.TYPE_FLOAT, 0.0],
  ["mapTex", ::ecs.TYPE_STRING],
  ["farMapTex", ::ecs.TYPE_STRING, null]
]}

local minimapQuery = ::ecs.SqQuery("minimapQuery", mmapComps)

local config = {
  mapColor = Color(255, 255, 255, 255)
  fovColor = Color(10, 0, 0, 200)
  mapTex = ""
  left_top = Point2(0,0)
  right_bottom = Point2(0,0)
  northAngle = 0.0
}


local mmContext = persist("ctx", function() {
  local ctx = MinimapContext()
  ctx.setup(config)
  return ctx
})

local function onMinimap(eid, comp){
  local isFarMap = (inPlane.value && (comp["farMapTex"] != null))
  mmContext.setup(config.__merge({
    mapTex = isFarMap ? comp["farMapTex"] : comp["mapTex"]
    right_bottom = isFarMap ? comp["farRightBottom"] : comp["right_bottom"]
    left_top = isFarMap ? comp["farLeftTop"] : comp["left_top"]
    northAngle = comp["northAngle"]
  }))
}

inPlane.subscribe(function(_) {
  minimapQuery.perform(onMinimap)
})

::ecs.register_es("minimap_ui_es", { onInit = onMinimap}, mmapComps)


return mmContext

 