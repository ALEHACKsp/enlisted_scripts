local {trackPlayerStart = null} = require("demo_track_player.nut")
if (trackPlayerStart==null)
  return
local { Point3 } = require("dagor.math")
local { take_screenshot_name=@(name) null } = require_optional("screencap")
local { argv } = require("dagor.system")
local string = require("string")

local points = []

local screenshot_name = "name_not_set"
foreach (a in argv)
  if (a && string.startswith(a, "screenshot_name="))
    screenshot_name = string.split(a, "=")[1]

foreach (a in argv)
  if (a && string.startswith(a, "screenshot_pos=")) {
    local coords = string.split(string.split(a, "=")[1], ",")
    points.append({ pos = Point3(coords[0].tofloat(), coords[1].tofloat(), coords[2].tofloat()) })
  }

local index = 0;
foreach (a in argv)
  if (a && string.startswith(a, "screenshot_dir=")) {
    local coords = string.split(string.split(a, "=")[1], ",")
    points[index].dir <- Point3(coords[0].tofloat(), coords[1].tofloat(), coords[2].tofloat())
    index++
  }


local batch = []
local count = 1
foreach (p in points) {
  local fileName = $"{screenshot_name}_{count++}";
  batch.append({duration=4.0, from_pos=p.pos, from_dir=p.dir, from_fov=90.0, to_pos=p.pos, to_dir=p.dir, to_fov=90.0})
  batch.append( function() { take_screenshot_name(fileName); } )
  batch.append({duration=0.5, from_pos=p.pos, from_dir=p.dir, from_fov=90.0, to_pos=p.pos, to_dir=p.dir, to_fov=90.0})
}

local hasStarted = false
::ecs.register_es("take_screenshots", {
  function onInit(eid, comp){
    if (batch.len() > 0 && !hasStarted) {
      hasStarted=true
      trackPlayerStart( batch )
    }
  }
},{comps_rq=["take_screenshots"]})
 