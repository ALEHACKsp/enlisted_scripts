local { battleAreasPolygon } = require("enlisted/ui/hud/state/hud_battle_areas_es.nut")


local function makeZone(battleAreasPolygonVal, minimap_state, map_size) {
  local commands = [[VECTOR_INVERSE_POLY]]
  return {
    color = Color(0, 0, 0, 150)
    fillColor = Color(0, 0, 0, 150)

    rendObj = ROBJ_VECTOR_CANVAS
    commands = commands
    lineWidth = hdpx(1)

    minimapState = minimap_state
    size = map_size

    points = battleAreasPolygonVal
    behavior = Behaviors.MinimapCanvasPolygon
  }
}


return ::Computed(function() {
  local battleAreasPolygonVal = battleAreasPolygon.value
  return {
    ctor = battleAreasPolygonVal == null ? @(p) []
      : @(p) [makeZone(battleAreasPolygonVal, p.state, p.size)]
  }
})
 