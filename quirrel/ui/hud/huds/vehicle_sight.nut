local {watchedHeroEid} = require("ui/hud/state/hero_state_es.nut")
local {controlledVehicleEid} = require("ui/hud/state/vehicle_state.nut")
local {mainTurretEid} = require("ui/hud/huds/player_info/vehicle_turret_state.nut")

local function bg_image(image, size) {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = size
    transform = { translate=[0.5 * (sw(100.0) - size[0]), 0.5 * (sh(100.0) - size[1])] }
    rendObj = ROBJ_IMAGE
    image = image
  }
}

local function bg_driver() {
  local aspect_ratio = 249.0 / 80.0
  local size = [aspect_ratio * sh(80.0), sh(80.0)]
  return {
    size = [sw(100.0), sh(100.0)]
    transform = {}
    children = [
      bg_image(Picture("ui/skin#driver_mask"), size)
    ]
  }
}

local crosshair_distances = [
  [ 200,  0],
  [ 400,  4],
  [ 600,  0],
  [ 800,  8],
  [1000,  0],
  [1200, 12],
  [1400,  0],
  [1600, 16],
  [1800,  0],
  [2000, 20],
  [2200,  0],
  [2400, 24],
  [2600,  0],
  [2800, 28]
]

local crosshair_hor_ranges = [ // in thousandth
  [-32, 32],
  [-28, 0 ],
  [-24, 24],
  [-20, 0 ],
  [-16, 16],
  [-12, 0 ],
  [-8,  8 ],
  [-4,  0 ],
  [ 4,  0 ],
  [ 8,  8 ],
  [ 12, 0 ],
  [ 16, 16],
  [ 20, 0 ],
  [ 24, 24],
  [ 28, 0 ],
  [ 32, 32]
]

local function central_lines() {
  return {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color = Color(0, 0, 0, 255)
    fillColor = Color(0, 0, 0, 25)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [sw(160.0), sh(160.0)]
    commands = [
      [VECTOR_WIDTH, 1],
      [VECTOR_LINE, 0, 50, 100, 50],
      [VECTOR_LINE, 50, 0, 50, 100],
    ]
  }
}

local function hor_ranges() {
  local children = crosshair_hor_ranges.map(@(dist){
    pos = [sh(50), sh(46)]
    font = Fonts.small_text
    color = Color(0, 0, 0, 255)
    rendObj = ROBJ_STEXT
    distance = dist[0]
    text = dist[1] > 0 ? dist[1] : ""
  })
  return {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color = Color(0, 0, 0, 255)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [sh(100.0), sh(100.0)]
    xhairMode = "horRanges"
    children = children
    commands = array(crosshair_hor_ranges.len()).map(@(...) [VECTOR_LINE, 0, 0, 0, 0])
  }
}

local function bullet_distance_marks() {
  local children = crosshair_distances.map(@(dist){
    pos = [sh(46), sh(50)]
    font = Fonts.small_text
    color = Color(0, 0, 0, 255)
    rendObj = ROBJ_STEXT
    distance = dist[0]
    text = dist[1] > 0 ? dist[1] : ""
    transform = { scale = [0.85, 0.85] }
  })
  return {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color = Color(0, 0, 0, 255)
    rendObj = ROBJ_VECTOR_CANVAS
    size = [sh(100.0), sh(100.0)]
    xhairMode = "bulletDistanceMarks"
    children = children
    commands = array(crosshair_distances.len()).map(@(...) [VECTOR_LINE, 0, 0, 0, 0])
  }
}

local function gunner_sight() {
  return {
    size = [sw(100.0), sh(100.0)]
    isHidden = true
    transform = {}
    xhairMode = "gunnerSight"
    children = [
      central_lines,
      bullet_distance_marks,
      hor_ranges
    ]
  }
}

local function driver_sight() {
  return {
    size = [sw(100.0), sh(100.0)]
    isHidden = true
    transform = {}
    xhairMode = "driverSight"
    children = [
      bg_driver
    ]
  }
}

local function sight() {
  return {
    size = [sw(100.0), sh(100.0)]
    isHidden = true
    behavior = Behaviors.VehicleSight
    transform = {}
    opacity = 0.1

    watch = [watchedHeroEid, controlledVehicleEid, mainTurretEid]
    eid = controlledVehicleEid.value
    watchedHeroEid = watchedHeroEid.value
    turretEid = mainTurretEid.value

    children = [
      gunner_sight
      driver_sight
    ]
  }
}

return sight
 