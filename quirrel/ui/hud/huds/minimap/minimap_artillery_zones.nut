                                          

local dagorMath = require("dagor.math")

local artilleryStrikes = require("ui/hud/state/artillery_strikes_es.nut")


local zeroPos = dagorMath.Point3(0,0,0)

local function makeZone(zone, minimap_state, map_size) {
  local worldPos = zone?["pos"] ?? zeroPos
  local radius = zone?["radius"] ?? 0.0
  local ellipseCmd = [VECTOR_ELLIPSE, 50, 50, 50, 50]
  local fillColor = Color(84, 24, 24, 5)

  local cmd = [
      [VECTOR_FILL_COLOR, fillColor],
      [VECTOR_WIDTH, 0],
      ellipseCmd,
    ]

  local updCacheTbl = {
    data = {
      worldPos = worldPos
      clampToBorder = false
    }
  }

  return {
    transform = {
      pivot = [0.5, 0.5]
    }
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(0)
    color = Color(0, 0, 0, 0)
    fillColor = fillColor

    behavior = Behaviors.RtPropUpdate
    rtAlwaysUpdate = false
    size = map_size
    commands = cmd

    update = function() {
      local realVisRadius = minimap_state.getVisibleRadius()
      local canvasRadius = radius / realVisRadius * 50.0

      ellipseCmd[3] = canvasRadius
      ellipseCmd[4] = canvasRadius

      updCacheTbl.data.worldPos <- worldPos
      return updCacheTbl
    }
  }
}

// map_size must be in pixels
local zones = ::kwarg(@(artilleryStrikesVal, state = null, size = null)
  artilleryStrikesVal.map(@(zone) makeZone(zone, state, size))
)

return ::Computed(function() {
  local artilleryStrikesVal = artilleryStrikes.value ?? []
  return { ctor = @(params) zones(params.__merge({ artilleryStrikesVal = artilleryStrikesVal })) }
})
 