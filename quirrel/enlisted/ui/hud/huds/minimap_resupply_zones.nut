local { resupplyZones, heroActiveResupplyZonesEids } = require("enlisted/ui/hud/state/resupplyZones.nut")
local string = require("string")

local markerSize = sh(2)
local iconSize = markerSize/1.5

local getPicture = ::memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = string.endswith(name,".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name
  }

  if (!imagename) {
    logerr("no image found")
    return null
  }

  return ::Picture(imagename)
}, @(name, iconSz) "".concat(name, iconSz))

local darkback = ::memoize(@(height) {
  size = [height, height]
  rendObj = ROBJ_IMAGE
  image = ::Picture("ui/uiskin/white_circle.png?Ac")
  color = Color(0, 0, 0, 120)
})

local function mkResupplyMarker(eid, options = null) {
  local zone = resupplyZones.value?[eid]
  local icon = {
    rendObj = ROBJ_IMAGE
    size = [iconSize.tointeger(), iconSize.tointeger()]
    image = getPicture(zone?.icon, iconSize)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {rotate = -90}
  }

  return {
    data = { eid = eid }
    transform = {}
    size = [markerSize.tointeger(), markerSize.tointeger()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      darkback(markerSize)
      icon
    ]
  }
}

return Computed(@() {
  ctor = @(p) heroActiveResupplyZonesEids.value.reduce(@(res, eid) res.append(mkResupplyMarker(eid, p)), [])
}) 