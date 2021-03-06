local mortarMarkers = require("common_shooter/ui/hud/state/mortar_markers.nut")

local mortarMarkerMapIconSize = [sh(2.25), sh(2.25)]

local mortarImages = {
  mortarKill = ::Picture("!ui/skin#skull.svg:{0}:{1}:K".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
  mortarShellExplode = ::Picture("!ui/skin#launcher.svg:{0}:{1}:K".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
}

local function mkMortarMarker(marker){
  return {
    image = mortarImages?[marker.type]
    size = mortarMarkerMapIconSize
    valign = ALIGN_CENTER
    transform = {
      pivot=[0.5, 0.5]
      rotate = -90
    }
    rendObj = ROBJ_IMAGE
    data = {
      worldPos = marker.pos
    }
  }
}

return Computed(@() { ctor = @(p) mortarMarkers.value.reduce(@(res, marker) res.append(mkMortarMarker(marker)), [])}) 