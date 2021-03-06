local {CmdDeleteMapUserPoint} = require("mapuserpointsevents")
local markSz = [sh(2), sh(2.6)]

local function mkPointMarkerCtor(params = {image = null, colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}}){
  return function(eid, marker, options) {
    local {byLocalPlayer=false} = marker

    local pin = ::watchElemState(function(sf) {
      local color
      if (byLocalPlayer) {
        color = (sf & S_HOVER) ? params?.colors.myHover : params?.colors.myDef
      } else {
        color = (sf & S_HOVER) ? params?.colors.foreignHover : params?.colors.foreignDef
      }

      return {
        size = params?.size ?? markSz
        rendObj = ROBJ_IMAGE
        color = color
        image = params?.image
        behavior = options?.isInteractive && byLocalPlayer ? Behaviors.Button : null
        onClick = byLocalPlayer ? @()::ecs.g_entity_mgr.sendEvent(eid, CmdDeleteMapUserPoint()) : null
      }
    })

    local icon = {
      size = [0, 0]
      halign = ALIGN_CENTER
      valign = params?.valign ?? ALIGN_BOTTOM
      transform = options?.transform
      children = pin
    }

    return {
      key = eid
      data = {
        eid = eid
        clampToBorder = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}

      children = [icon]
    }
  }
}

return {
  mkPointMarkerCtor = mkPointMarkerCtor
} 