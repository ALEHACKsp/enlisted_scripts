local canDropColor = Color(255,225,105,105)
local dropBorderColor = Color(105,65,15,75)
local canDropAreaColor = Color(25,25,15,15)
local canDropBorder = hdpx(1.5)
local function dropMarker(stateFlags=0) {
  return {
    rendObj = ROBJ_BOX
    borderWidth = canDropBorder
    borderColor = (stateFlags & S_ACTIVE) ? canDropColor : dropBorderColor
    size=flex()
    fillColor = canDropAreaColor
    key = stateFlags
    animations = (stateFlags & S_ACTIVE) ? [] : [
//      { prop=AnimProp.borderColor, from=canDropColor, to=dropAreaColor, duration=1.2, play=true, loop=true, easing=CosineFull }
      { prop=AnimProp.fillColor, from=Color(0,0,0,0), to=canDropAreaColor, duration=1.2, play=true, loop=true, easing=CosineFull }
    ]
  }
}

return dropMarker 