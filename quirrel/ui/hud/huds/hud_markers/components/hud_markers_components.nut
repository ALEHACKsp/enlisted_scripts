local myDefMarkColor = Color(250,250,50,250)
local forDefMarkColor = Color(180,180,250,250)
local defTransform = {}

local arrowSize = [sh(2.5), sh(1.2)]
local arrowPos = [0, 0]
local arrowImage = ::Picture("ui/skin#v_arrow")
local makeArrow = ::kwarg(function(yOffs = 0, pos = arrowPos, anim=null, color=null, key=null) {
  return {
    markerFlags = MARKER_ARROW
    transform = defTransform
    pos = [0, yOffs]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_IMAGE
      image = arrowImage
      key = key ?? anim
      size = arrowSize
      color = color
      pos = pos
      animations = anim
    }
  }
})

local markSz = [sh(2), sh(2.6)]
//local markerDistanceTextBhv = [Behaviors.DistToPriority, Behaviors.OverlayTransparency, Behaviors.DistToEntity]
//local markerDistanceTextSize = [sh(5), SIZE_TO_CONTENT]

local function mkPointMarkerCtor(params = {image = null, colors = {myDef = myDefMarkColor, foreignDef = forDefMarkColor}}){
  local mkIcon = ::memoize(@(color) {
    rendObj = ROBJ_IMAGE
    size = params?.size ?? markSz
    pos = [0, sh(params?.yOffs ?? 0)]
    color = color
    image = params?.image
    animations = params?.animations
  })
  local mkArrow = @(color) makeArrow({color=color, yOffs=sh(2), anim = null})
  return function(eid, marker) {
    local {byLocalPlayer=false} = marker
    local color = byLocalPlayer ? params?.colors.myDef : params?.colors.foreignDef

/*
    local distanceText = null
    if (marker.showDistanceRear) {
      distanceText = {
        data = { eid = eid }
        targetEid = eid
        rendObj = ROBJ_DTEXT
        color = DEFAULT_TEXT_COLOR
        behavior = markerDistanceTextBhv
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = markerDistanceTextSize
        pos = [0, sh(params?.yDistOffs ?? 0)]
        markerFlags = MARKER_KEEP_SCALE | MARKER_SHOW_ONLY_WHEN_CLAMPED
        transform = defTransform
      }
    }

*/
    return {
      data = {
        eid = eid
        minDistance = 0.7
        maxDistance = 10000
        distScaleFactor = 0.5
        clampToBorder = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      transform = defTransform
      key = eid
      sortOrder = eid

      children = [mkIcon(color), mkArrow(color)]
    }
  }
}

return {
  mkPointMarkerCtor = mkPointMarkerCtor
  makeArrow = makeArrow
} 